#####
##### Precomputed quantities
#####
import Thermodynamics as TD
import ClimaCore: Spaces, Fields

"""
    set_prognostic_edmf_precomputed_quantities!(Y, p, ᶠuₕ³, t)

Updates the edmf environment precomputed quantities stored in `p` for edmfx.
"""
function set_prognostic_edmf_precomputed_quantities_environment!(Y, p, ᶠuₕ³, t)
    @assert !(p.atmos.moisture_model isa DryModel)

    thermo_params = CAP.thermodynamics_params(p.params)
    (; turbconv_model) = p.atmos
    (; ᶜΦ,) = p.core
    (; ᶜp, ᶜh_tot, ᶜK) = p.precomputed
    (; ᶜtke⁰, ᶜρa⁰, ᶠu₃⁰, ᶜu⁰, ᶠu³⁰, ᶜK⁰, ᶜts⁰, ᶜρ⁰, ᶜmse⁰, ᶜq_tot⁰) =
        p.precomputed

    @. ᶜρa⁰ = ρa⁰(Y.c)
    @. ᶜtke⁰ = divide_by_ρa(Y.c.sgs⁰.ρatke, ᶜρa⁰, 0, Y.c.ρ, turbconv_model)
    @. ᶜmse⁰ = divide_by_ρa(
        Y.c.ρ * (ᶜh_tot - ᶜK) - ρamse⁺(Y.c.sgsʲs),
        ᶜρa⁰,
        Y.c.ρ * (ᶜh_tot - ᶜK),
        Y.c.ρ,
        turbconv_model,
    )
    @. ᶜq_tot⁰ = divide_by_ρa(
        Y.c.ρq_tot - ρaq_tot⁺(Y.c.sgsʲs),
        ᶜρa⁰,
        Y.c.ρq_tot,
        Y.c.ρ,
        turbconv_model,
    )
    set_sgs_ᶠu₃!(u₃⁰, ᶠu₃⁰, Y, turbconv_model)
    set_velocity_quantities!(ᶜu⁰, ᶠu³⁰, ᶜK⁰, ᶠu₃⁰, Y.c.uₕ, ᶠuₕ³)
    # @. ᶜK⁰ += ᶜtke⁰
    @. ᶜts⁰ = TD.PhaseEquil_phq(thermo_params, ᶜp, ᶜmse⁰ - ᶜΦ, ᶜq_tot⁰)
    @. ᶜρ⁰ = TD.air_density(thermo_params, ᶜts⁰)
    return nothing
end

"""
    set_prognostic_edmf_precomputed_quantities_draft_and_bc!(Y, p, ᶠuₕ³, t)

Updates the draft thermo state and boundary conditions
precomputed quantities stored in `p` for edmfx.
"""
function set_prognostic_edmf_precomputed_quantities_draft_and_bc!(Y, p, ᶠuₕ³, t)
    (; moisture_model, turbconv_model) = p.atmos
    #EDMFX BCs only support total energy as state variable
    @assert !(moisture_model isa DryModel)

    FT = Spaces.undertype(axes(Y.c))
    n = n_mass_flux_subdomains(turbconv_model)

    (; params) = p
    thermo_params = CAP.thermodynamics_params(params)

    (; ᶜΦ,) = p.core
    (; ᶜspecific, ᶜp, ᶜh_tot, ᶜK) = p.precomputed
    (; ᶜuʲs, ᶠu³ʲs, ᶜKʲs, ᶜtsʲs, ᶜρʲs) = p.precomputed
    (; ustar, obukhov_length, buoyancy_flux) = p.precomputed.sfc_conditions

    for j in 1:n
        ᶜuʲ = ᶜuʲs.:($j)
        ᶠu³ʲ = ᶠu³ʲs.:($j)
        ᶜKʲ = ᶜKʲs.:($j)
        ᶠu₃ʲ = Y.f.sgsʲs.:($j).u₃
        ᶜtsʲ = ᶜtsʲs.:($j)
        ᶜρʲ = ᶜρʲs.:($j)
        ᶜmseʲ = Y.c.sgsʲs.:($j).mse
        ᶜq_totʲ = Y.c.sgsʲs.:($j).q_tot

        set_velocity_quantities!(ᶜuʲ, ᶠu³ʲ, ᶜKʲ, ᶠu₃ʲ, Y.c.uₕ, ᶠuₕ³)
        @. ᶜtsʲ = TD.PhaseEquil_phq(thermo_params, ᶜp, ᶜmseʲ - ᶜΦ, ᶜq_totʲ)
        @. ᶜρʲ = TD.air_density(thermo_params, ᶜtsʲ)

        # EDMFX boundary condition:

        # We need field_values everywhere because we are mixing
        # information from surface and first interior inside the
        # sgs_h/q_tot_first_interior_bc call.
        ᶜz_int_val =
            Fields.field_values(Fields.level(Fields.coordinate_field(Y.c).z, 1))
        z_sfc_val = Fields.field_values(
            Fields.level(Fields.coordinate_field(Y.f).z, Fields.half),
        )
        ᶜρ_int_val = Fields.field_values(Fields.level(Y.c.ρ, 1))
        ᶜp_int_val = Fields.field_values(Fields.level(ᶜp, 1))
        (; ρ_flux_h_tot, ρ_flux_q_tot, ustar, obukhov_length) =
            p.precomputed.sfc_conditions
        buoyancy_flux_val = Fields.field_values(buoyancy_flux)
        ρ_flux_h_tot_val = Fields.field_values(ρ_flux_h_tot)
        ρ_flux_q_tot_val = Fields.field_values(ρ_flux_q_tot)
        ustar_val = Fields.field_values(ustar)
        obukhov_length_val = Fields.field_values(obukhov_length)
        sfc_local_geometry_val = Fields.field_values(
            Fields.local_geometry_field(Fields.level(Y.f, Fields.half)),
        )

        # Based on boundary conditions for updrafts we overwrite
        # the first interior point for EDMFX ᶜh_totʲ...
        ᶜh_tot_int_val = Fields.field_values(Fields.level(ᶜh_tot, 1))
        ᶜK_int_val = Fields.field_values(Fields.level(ᶜK, 1))
        ᶜmseʲ_int_val = Fields.field_values(Fields.level(ᶜmseʲ, 1))
        @. ᶜmseʲ_int_val = sgs_scalar_first_interior_bc(
            ᶜz_int_val - z_sfc_val,
            ᶜρ_int_val,
            ᶜh_tot_int_val - ᶜK_int_val,
            buoyancy_flux_val,
            ρ_flux_h_tot_val,
            ustar_val,
            obukhov_length_val,
            sfc_local_geometry_val,
        )

        # ... and the first interior point for EDMFX ᶜq_totʲ.
        ᶜq_tot_int_val = Fields.field_values(Fields.level(ᶜspecific.q_tot, 1))
        ᶜq_totʲ_int_val = Fields.field_values(Fields.level(ᶜq_totʲ, 1))
        @. ᶜq_totʲ_int_val = sgs_scalar_first_interior_bc(
            ᶜz_int_val - z_sfc_val,
            ᶜρ_int_val,
            ᶜq_tot_int_val,
            buoyancy_flux_val,
            ρ_flux_q_tot_val,
            ustar_val,
            obukhov_length_val,
            sfc_local_geometry_val,
        )

        # Then overwrite the prognostic variables at first inetrior point.
        ᶜΦ_int_val = Fields.field_values(Fields.level(ᶜΦ, 1))
        ᶜtsʲ_int_val = Fields.field_values(Fields.level(ᶜtsʲ, 1))
        @. ᶜtsʲ_int_val = TD.PhaseEquil_phq(
            thermo_params,
            ᶜp_int_val,
            ᶜmseʲ_int_val - ᶜΦ_int_val,
            ᶜq_totʲ_int_val,
        )
        sgsʲs_ρ_int_val = Fields.field_values(Fields.level(ᶜρʲs.:($j), 1))
        sgsʲs_ρa_int_val =
            Fields.field_values(Fields.level(Y.c.sgsʲs.:($j).ρa, 1))

        turbconv_params = CAP.turbconv_params(params)
        @. sgsʲs_ρ_int_val = TD.air_density(thermo_params, ᶜtsʲ_int_val)
        @. sgsʲs_ρa_int_val =
            $(FT(turbconv_params.surface_area)) *
            TD.air_density(thermo_params, ᶜtsʲ_int_val)
    end
    return nothing
end

"""
    set_prognostic_edmf_precomputed_quantities_closures!(Y, p, t)

Updates the precomputed quantities stored in `p` for edmfx closures.
"""
function set_prognostic_edmf_precomputed_quantities_closures!(Y, p, t)

    (; moisture_model, turbconv_model, precip_model) = p.atmos
    @assert !(moisture_model isa DryModel)

    (; params) = p
    (; dt) = p
    thermo_params = CAP.thermodynamics_params(params)
    microphys_params = CAP.microphysics_params(params)

    FT = eltype(params)
    n = n_mass_flux_subdomains(turbconv_model)

    (; ᶜtke⁰, ᶜu, ᶜp, ᶜρa⁰, ᶠu³⁰, ᶜts⁰, ᶜρ⁰, ᶜq_tot⁰) = p.precomputed
    (;
        ᶜmixing_length,
        ᶜlinear_buoygrad,
        ᶜstrain_rate_norm,
        ᶜK_u,
        ᶜK_h,
        ρatke_flux,
    ) = p.precomputed
    (; ᶜuʲs, ᶜtsʲs, ᶠu³ʲs, ᶜρʲs, ᶜentrʲs, ᶜdetrʲs) = p.precomputed
    (; ᶜS_q_totʲs, ᶜS_q_tot⁰) = p.precomputed
    (; ustar, obukhov_length, buoyancy_flux) = p.precomputed.sfc_conditions

    ᶜz = Fields.coordinate_field(Y.c).z
    z_sfc = Fields.level(Fields.coordinate_field(Y.f).z, Fields.half)
    ᶜdz = Fields.Δz_field(axes(Y.c))
    ᶜlg = Fields.local_geometry_field(Y.c)

    ᶜvert_div = p.scratch.ᶜtemp_scalar
    for j in 1:n
        # entrainment/detrainment
        @. ᶜentrʲs.:($$j) = entrainment(
            params,
            ᶜz,
            z_sfc,
            ᶜp,
            Y.c.ρ,
            buoyancy_flux,
            draft_area(Y.c.sgsʲs.:($$j).ρa, ᶜρʲs.:($$j)),
            get_physical_w(ᶜuʲs.:($$j), ᶜlg),
            TD.relative_humidity(thermo_params, ᶜtsʲs.:($$j)),
            ᶜphysical_buoyancy(params, Y.c.ρ, ᶜρʲs.:($$j)),
            get_physical_w(ᶜu, ᶜlg),
            TD.relative_humidity(thermo_params, ᶜts⁰),
            FT(0),
            p.atmos.edmfx_entr_model,
        )
        @. ᶜentrʲs.:($$j) = limit_entrainment(
            ᶜentrʲs.:($$j),
            draft_area(Y.c.sgsʲs.:($$j).ρa, ᶜρʲs.:($$j)),
            dt,
        )
        @. ᶜvert_div = ᶜdivᵥ(ᶠinterp(ᶜρʲs.:($$j)) * ᶠu³ʲs.:($$j)) / ᶜρʲs.:($$j)
        @. ᶜdetrʲs.:($$j) = detrainment(
            params,
            ᶜz,
            z_sfc,
            ᶜp,
            Y.c.ρ,
            buoyancy_flux,
            draft_area(Y.c.sgsʲs.:($$j).ρa, ᶜρʲs.:($$j)),
            get_physical_w(ᶜuʲs.:($$j), ᶜlg),
            TD.relative_humidity(thermo_params, ᶜtsʲs.:($$j)),
            ᶜphysical_buoyancy(params, Y.c.ρ, ᶜρʲs.:($$j)),
            get_physical_w(ᶜu, ᶜlg),
            TD.relative_humidity(thermo_params, ᶜts⁰),
            FT(0),
            ᶜentrʲs.:($$j),
            ᶜvert_div,
            p.atmos.edmfx_detr_model,
        )
        @. ᶜdetrʲs.:($$j) = limit_detrainment(
            ᶜdetrʲs.:($$j),
            draft_area(Y.c.sgsʲs.:($$j).ρa, ᶜρʲs.:($$j)),
            dt,
        )
        # precipitation
        @. ᶜS_q_totʲs.:($$j) = q_tot_precipitation_sources(
            precip_model,
            thermo_params,
            microphys_params,
            dt,
            Y.c.sgsʲs.:($$j).q_tot,
            ᶜtsʲs.:($$j),
        )
    end

    @. ᶜS_q_tot⁰ = q_tot_precipitation_sources(
        precip_model,
        thermo_params,
        microphys_params,
        dt,
        ᶜq_tot⁰,
        ᶜts⁰,
    )

    # First order approximation: Use environmental mean fields.
    @. ᶜlinear_buoygrad = buoyancy_gradients(
        BuoyGradMean(),
        thermo_params,
        moisture_model,
        EnvBuoyGradVars(
            thermo_params,
            ᶜts⁰,
            projected_vector_buoy_grad_vars(
                C3,
                ᶜgradᵥ(ᶠinterp(TD.virtual_pottemp(thermo_params, ᶜts⁰))),    # ∂θv∂z_unsat
                ᶜgradᵥ(ᶠinterp(ᶜq_tot⁰)),                                    # ∂qt∂z_sat
                ᶜgradᵥ(ᶠinterp(TD.liquid_ice_pottemp(thermo_params, ᶜts⁰))), # ∂θl∂z_sat
                ᶜlg,
            ),
        ),
    )

    # TODO: Currently the shear production only includes vertical gradients
    ᶠu⁰ = p.scratch.ᶠtemp_C123
    @. ᶠu⁰ = C123(ᶠinterp(Y.c.uₕ)) + C123(ᶠu³⁰)
    ᶜstrain_rate = p.scratch.ᶜtemp_UVWxUVW
    compute_strain_rate_center!(ᶜstrain_rate, ᶠu⁰)
    @. ᶜstrain_rate_norm = norm_sqr(ᶜstrain_rate)

    ᶜprandtl_nvec = p.scratch.ᶜtemp_scalar
    @. ᶜprandtl_nvec = turbulent_prandtl_number(
        params,
        obukhov_length,
        ᶜlinear_buoygrad,
        ᶜstrain_rate_norm,
    )
    ᶜtke_exch = p.scratch.ᶜtemp_scalar_2
    @. ᶜtke_exch = 0
    for j in 1:n
        ᶠu³ʲ = ᶠu³ʲs.:($j)
        @. ᶜtke_exch +=
            Y.c.sgsʲs.:($$j).ρa * ᶜdetrʲs.:($$j) / ᶜρa⁰ *
            (1 / 2 * norm_sqr(ᶜinterp(ᶠu³⁰) - ᶜinterp(ᶠu³ʲs.:($$j))) - ᶜtke⁰)
    end

    sfc_tke = Fields.level(ᶜtke⁰, 1)
    @. ᶜmixing_length = mixing_length(
        p.params,
        ustar,
        ᶜz,
        z_sfc,
        ᶜdz,
        max(sfc_tke, eps(FT)),
        ᶜlinear_buoygrad,
        max(ᶜtke⁰, 0),
        obukhov_length,
        ᶜstrain_rate_norm,
        ᶜprandtl_nvec,
        ᶜtke_exch,
    )

    turbconv_params = CAP.turbconv_params(params)
    c_m = CAP.tke_ed_coeff(turbconv_params)
    @. ᶜK_u = c_m * ᶜmixing_length * sqrt(max(ᶜtke⁰, 0))
    @. ᶜK_h = ᶜK_u / ᶜprandtl_nvec

    ρatke_flux_values = Fields.field_values(ρatke_flux)
    ρ_int_values = Fields.field_values(Fields.level(ᶜρa⁰, 1))
    u_int_values = Fields.field_values(Fields.level(ᶜu, 1))
    ustar_values = Fields.field_values(ustar)
    int_local_geometry_values =
        Fields.field_values(Fields.level(Fields.local_geometry_field(Y.c), 1))
    sfc_local_geometry_values = Fields.field_values(
        Fields.level(Fields.local_geometry_field(Y.f), half),
    )
    @. ρatke_flux_values = surface_flux_tke(
        turbconv_params,
        ρ_int_values,
        u_int_values,
        ustar_values,
        int_local_geometry_values,
        sfc_local_geometry_values,
    )

    return nothing
end
