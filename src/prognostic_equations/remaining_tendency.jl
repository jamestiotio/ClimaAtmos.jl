
NVTX.@annotate function remaining_tendency!(Yₜ, Y, p, t)
    fill_with_nans!(p)
    Yₜ .= zero(eltype(Yₜ))
    NVTX.@range "horizontal" color = colorant"orange" begin
        horizontal_advection_tendency!(Yₜ, Y, p, t)
        hyperdiffusion_tendency!(Yₜ, Y, p, t)
    end
    explicit_vertical_advection_tendency!(Yₜ, Y, p, t)
    additional_tendency!(Yₜ, Y, p, t)
    return Yₜ
end

NVTX.@annotate function additional_tendency!(Yₜ, Y, p, t)
    viscous_sponge_tendency!(Yₜ, Y, p, t, p.atmos.viscous_sponge)
    surface_temp_tendency!(Yₜ, Y, p, t, p.atmos.surface_model)

    # Vertical tendencies
    Fields.bycolumn(axes(Y.c)) do colidx
        rayleigh_sponge_tendency!(Yₜ, Y, p, t, colidx, p.atmos.rayleigh_sponge)
        forcing_tendency!(Yₜ, Y, p, t, colidx, p.atmos.forcing_type)
        subsidence_tendency!(Yₜ, Y, p, t, colidx, p.atmos.subsidence)
        edmf_coriolis_tendency!(Yₜ, Y, p, t, colidx, p.atmos.edmf_coriolis)
        large_scale_advection_tendency!(Yₜ, Y, p, t, colidx, p.atmos.ls_adv)

        if p.atmos.diff_mode == Explicit()
            vertical_diffusion_boundary_layer_tendency!(
                Yₜ,
                Y,
                p,
                t,
                colidx,
                p.atmos.vert_diff,
            )
            edmfx_sgs_diffusive_flux_tendency!(
                Yₜ,
                Y,
                p,
                t,
                colidx,
                p.atmos.turbconv_model,
            )
        end

        radiation_tendency!(Yₜ, Y, p, t, colidx, p.atmos.radiation_mode)
        edmfx_sgs_vertical_advection_tendency!(
            Yₜ,
            Y,
            p,
            t,
            colidx,
            p.atmos.turbconv_model,
        )
        edmfx_entr_detr_tendency!(Yₜ, Y, p, t, colidx, p.atmos.turbconv_model)
        edmfx_sgs_mass_flux_tendency!(
            Yₜ,
            Y,
            p,
            t,
            colidx,
            p.atmos.turbconv_model,
        )
        edmfx_nh_pressure_tendency!(Yₜ, Y, p, t, colidx, p.atmos.turbconv_model)
        edmfx_tke_tendency!(Yₜ, Y, p, t, colidx, p.atmos.turbconv_model)
        edmfx_precipitation_tendency!(
            Yₜ,
            Y,
            p,
            t,
            colidx,
            p.atmos.turbconv_model,
            p.atmos.precip_model,
        )
        precipitation_tendency!(Yₜ, Y, p, t, colidx, p.atmos.precip_model)

        # NOTE: All ρa tendencies should be applied before calling this function
        pressure_work_tendency!(Yₜ, Y, p, t, colidx, p.atmos.turbconv_model)

        # NOTE: This will zero out all momentum tendencies in the edmfx advection test
        # please DO NOT add additional velocity tendencies after this function
        zero_velocity_tendency!(Yₜ, Y, p, t, colidx)
    end
    # TODO: make bycolumn-able
    non_orographic_gravity_wave_tendency!(
        Yₜ,
        Y,
        p,
        t,
        p.atmos.non_orographic_gravity_wave,
    )
    orographic_gravity_wave_tendency!(
        Yₜ,
        Y,
        p,
        t,
        p.atmos.orographic_gravity_wave,
    )
end
