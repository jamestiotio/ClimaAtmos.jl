include("initial_conditions/dry_shallow_baroclinic_wave.jl")

# Set up parameters
using CLIMAParameters
struct BalancedFlowParameters <: CLIMAParameters.AbstractEarthParameterSet end

function run_balanced_flow(
    ::Type{FT};
    stepper = SSPRK33(),
    nelements = (4, 10),
    npolynomial = 4,
    dt = 5.0,
    callbacks = (),
    mode = :regression,
) where {FT}
    params = BalancedFlowParameters()

    domain = SphericalShell(
        FT,
        radius = CLIMAParameters.Planet.planet_radius(params),
        height = FT(30.0e3),
        nelements = nelements,
        npolynomial = npolynomial,
    )

    model = Nonhydrostatic3DModel(
        domain = domain,
        boundary_conditions = nothing,
        parameters = params,
        flux_corr = false,
        hyperdiffusivity = FT(0),
    )

    # execute differently depending on testing mode
    if mode == :integration
        simulation = Simulation(model, stepper, dt = dt, tspan = (0.0, 2 * dt))
        @test simulation isa Simulation

        # test set function
        @unpack ρ, uh, w, ρe_tot =
            init_dry_shallow_baroclinic_wave(FT, params, isbalanced = true)
        set!(simulation, :base, ρ = ρ, uh = uh, w = w)
        set!(simulation, :thermodynamics, ρe_tot = ρe_tot)

        # test successful integration
        @test step!(simulation) isa Nothing # either error or integration runs
    elseif mode == :regression
        simulation = Simulation(model, stepper, dt = dt, tspan = (0.0, dt))
        @unpack ρ, uh, w, ρe_tot =
            init_dry_shallow_baroclinic_wave(FT, params, isbalanced = true)
        set!(simulation, :base, ρ = ρ, uh = uh, w = w)
        set!(simulation, :thermodynamics, ρe_tot = ρe_tot)
        step!(simulation)

        ub = simulation.integrator.u.base
        ut = simulation.integrator.u.thermodynamics
        uh_phy = Geometry.transform.(Ref(Geometry.UVAxis()), ub.uh)
        w_phy = Geometry.transform.(Ref(Geometry.WAxis()), ub.w)

        # perform regression check
        current_u_max = 27.8838476993762
        current_w_max = 1.1618705020355047
        current_ρ_max = 1.2104825974679885
        current_ρe_max = 34865.88430268488

        @test (uh_phy.components.data.:1 |> maximum) ≈ current_u_max rtol = 1e-2
        @test (abs.(w_phy |> parent) |> maximum) ≈ current_w_max rtol = 1e-2
        @test (ub.ρ |> maximum) ≈ current_ρ_max rtol = 1e-2
        @test (ut.ρe_tot |> maximum) ≈ current_ρe_max rtol = 1e-2
    elseif mode == :validation
        simulation = Simulation(model, stepper, dt = dt, tspan = (0.0, 3600))
        @unpack ρ, uh, w, ρe_tot =
            init_dry_shallow_baroclinic_wave(FT, params, isbalanced = true)
        set!(simulation, :base, ρ = ρ, uh = uh, w = w)
        set!(simulation, :thermodynamics, ρe_tot = ρe_tot)
        u_init = simulation.integrator.u

        run!(simulation)
        u_end = simulation.integrator.u

        @test u_end.base.ρ ≈ u_init.base.ρ rtol = 5e-2
        @test u_end.thermodynamics.ρe_tot ≈ u_init.thermodynamics.ρe_tot rtol =
            5e-2
        @test u_end.base.uh ≈ u_init.base.uh rtol = 5e-2
    else
        throw(ArgumentError("$mode incompatible with test case."))
    end

    nothing
end
