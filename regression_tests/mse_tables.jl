#################################
################################# MSE tables
#################################
#! format: off
#
all_best_mse = OrderedCollections.OrderedDict()
#
all_best_mse["sphere_held_suarez_rhotheta"] = OrderedCollections.OrderedDict()
all_best_mse["sphere_held_suarez_rhotheta"][(:c, :ρ)] = 0.0
all_best_mse["sphere_held_suarez_rhotheta"][(:c, :ρθ)] = 0.0
all_best_mse["sphere_held_suarez_rhotheta"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["sphere_held_suarez_rhotheta"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["sphere_held_suarez_rhotheta"][(:f, :w, :components, :data, 1)] = 0.0
#
all_best_mse["sphere_held_suarez_rhoe_equilmoist"] = OrderedCollections.OrderedDict()
all_best_mse["sphere_held_suarez_rhoe_equilmoist"][(:c, :ρ)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_equilmoist"][(:c, :ρe_tot)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_equilmoist"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_equilmoist"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_equilmoist"][(:c, :ρq_tot)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_equilmoist"][(:f, :w, :components, :data, 1)] = 0.0
#
all_best_mse["sphere_baroclinic_wave_rhoe"] = OrderedCollections.OrderedDict()
all_best_mse["sphere_baroclinic_wave_rhoe"][(:c, :ρ)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe"][(:c, :ρe_tot)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe"][(:f, :w, :components, :data, 1)] = 0.0
#
all_best_mse["sphere_baroclinic_wave_rhoe_equilmoist"] = OrderedCollections.OrderedDict()
all_best_mse["sphere_baroclinic_wave_rhoe_equilmoist"][(:c, :ρ)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe_equilmoist"][(:c, :ρe_tot)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe_equilmoist"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe_equilmoist"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe_equilmoist"][(:c, :ρq_tot)] = 0.0
all_best_mse["sphere_baroclinic_wave_rhoe_equilmoist"][(:f, :w, :components, :data, 1)] = 0.0
#
all_best_mse["sphere_held_suarez_rhoe"] = OrderedCollections.OrderedDict()
all_best_mse["sphere_held_suarez_rhoe"][(:c, :ρ)] = 0.0
all_best_mse["sphere_held_suarez_rhoe"][(:c, :ρe_tot)] = 0.0
all_best_mse["sphere_held_suarez_rhoe"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["sphere_held_suarez_rhoe"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["sphere_held_suarez_rhoe"][(:f, :w, :components, :data, 1)] = 0.0
#
all_best_mse["sphere_held_suarez_rhoe_int"] = OrderedCollections.OrderedDict()
all_best_mse["sphere_held_suarez_rhoe_int"][(:c, :ρ)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_int"][(:c, :ρe_int)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_int"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_int"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["sphere_held_suarez_rhoe_int"][(:f, :w, :components, :data, 1)] = 0.0
#
all_best_mse["sphere_aquaplanet_rhoe_equilmoist_allsky"] = OrderedCollections.OrderedDict()
all_best_mse["sphere_aquaplanet_rhoe_equilmoist_allsky"][(:c, :ρ)] = 0.0
all_best_mse["sphere_aquaplanet_rhoe_equilmoist_allsky"][(:c, :ρe_tot)] = 0.0
all_best_mse["sphere_aquaplanet_rhoe_equilmoist_allsky"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["sphere_aquaplanet_rhoe_equilmoist_allsky"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["sphere_aquaplanet_rhoe_equilmoist_allsky"][(:c, :ρq_tot)] = 0.0
all_best_mse["sphere_aquaplanet_rhoe_equilmoist_allsky"][(:f, :w, :components, :data, 1)] = 0.0
#
all_best_mse["edmf_bomex"] = OrderedCollections.OrderedDict()
all_best_mse["edmf_bomex"][(:c, :ρ)] = 0.0
all_best_mse["edmf_bomex"][(:c, :ρe_tot)] = 5.134965567277058e-6
all_best_mse["edmf_bomex"][(:c, :uₕ, :components, :data, 1)] = 6.330938315966505e-6
all_best_mse["edmf_bomex"][(:c, :uₕ, :components, :data, 2)] = 0.0003735337441205666
all_best_mse["edmf_bomex"][(:c, :ρq_tot)] = 3.2107495326353585e-5
all_best_mse["edmf_bomex"][(:c, :turbconv, :en, :ρatke)] = 0.0039648148460047
all_best_mse["edmf_bomex"][(:c, :turbconv, :up, 1, :ρarea)] = 0.00475759976576874
all_best_mse["edmf_bomex"][(:c, :turbconv, :up, 1, :ρaθ_liq_ice)] = 0.004763297717557296
all_best_mse["edmf_bomex"][(:c, :turbconv, :up, 1, :ρaq_tot)] = 0.0044974242304210744
all_best_mse["edmf_bomex"][(:f, :turbconv, :up, 1, :w)] = 0.0010282376913738733
#
all_best_mse["compressible_edmf_bomex"] = OrderedCollections.OrderedDict()
all_best_mse["compressible_edmf_bomex"][(:c, :ρ)] = 9.419600558706194e-9
all_best_mse["compressible_edmf_bomex"][(:c, :ρe_tot)] = 6.374278949641308e-6
all_best_mse["compressible_edmf_bomex"][(:c, :uₕ, :components, :data, 1)] = 2.0817226800534944e-5
all_best_mse["compressible_edmf_bomex"][(:c, :uₕ, :components, :data, 2)] = 0.001564028649813136
all_best_mse["compressible_edmf_bomex"][(:c, :ρq_tot)] = 3.94701173673035e-5
all_best_mse["compressible_edmf_bomex"][(:c, :turbconv, :en, :ρatke)] = 0.0036712693930077062
all_best_mse["compressible_edmf_bomex"][(:c, :turbconv, :up, 1, :ρarea)] = 0.005940455855528697
all_best_mse["compressible_edmf_bomex"][(:c, :turbconv, :up, 1, :ρaθ_liq_ice)] = 0.005950711468868688
all_best_mse["compressible_edmf_bomex"][(:c, :turbconv, :up, 1, :ρaq_tot)] = 0.005500417817384081
all_best_mse["compressible_edmf_bomex"][(:f, :turbconv, :up, 1, :w)] = 0.0012510248694108882
#
all_best_mse["edmf_dycoms_rf01"] = OrderedCollections.OrderedDict()
all_best_mse["edmf_dycoms_rf01"][(:c, :ρ)] = 0.0
all_best_mse["edmf_dycoms_rf01"][(:c, :ρe_tot)] = 3.345752553688445e-7
all_best_mse["edmf_dycoms_rf01"][(:c, :uₕ, :components, :data, 1)] = 1.8051410256791111e-6
all_best_mse["edmf_dycoms_rf01"][(:c, :uₕ, :components, :data, 2)] = 1.8051410256721892e-6
all_best_mse["edmf_dycoms_rf01"][(:c, :ρq_tot)] = 2.616763435394631e-6
all_best_mse["edmf_dycoms_rf01"][(:c, :turbconv, :en, :ρatke)] = 0.00023129130645056485
all_best_mse["edmf_dycoms_rf01"][(:c, :turbconv, :up, 1, :ρarea)] = 0.0009280529253972953
all_best_mse["edmf_dycoms_rf01"][(:c, :turbconv, :up, 1, :ρaθ_liq_ice)] = 0.000929334971538737
all_best_mse["edmf_dycoms_rf01"][(:c, :turbconv, :up, 1, :ρaq_tot)] = 0.0009378812902114916
all_best_mse["edmf_dycoms_rf01"][(:f, :turbconv, :up, 1, :w)] = 0.00011658883580596731
#
all_best_mse["compressible_edmf_dycoms_rf01"] = OrderedCollections.OrderedDict()
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :ρ)] = 1.134851813633173e-9
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :ρe_tot)] = 2.8602817762776077e-7
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :uₕ, :components, :data, 1)] = 1.8559733558178562e-6
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :uₕ, :components, :data, 2)] = 1.8559733557973582e-6
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :ρq_tot)] = 2.242945945886073e-6
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :turbconv, :en, :ρatke)] = 0.0005318396364997534
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :turbconv, :up, 1, :ρarea)] = 0.0006364880468412075
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :turbconv, :up, 1, :ρaθ_liq_ice)] = 0.0006374394177483895
all_best_mse["compressible_edmf_dycoms_rf01"][(:c, :turbconv, :up, 1, :ρaq_tot)] = 0.0006481902852398741
all_best_mse["compressible_edmf_dycoms_rf01"][(:f, :turbconv, :up, 1, :w)] = 9.145678796287693e-5
#
all_best_mse["edmf_trmm"] = OrderedCollections.OrderedDict()
all_best_mse["edmf_trmm"][(:c, :ρ)] = 0.0
all_best_mse["edmf_trmm"][(:c, :ρe_tot)] = 2.747744111547203e-6
all_best_mse["edmf_trmm"][(:c, :uₕ, :components, :data, 1)] = 2.5486684088340333e-5
all_best_mse["edmf_trmm"][(:c, :uₕ, :components, :data, 2)] = 4.738164285378556e-5
all_best_mse["edmf_trmm"][(:c, :ρq_tot)] = 4.682271068094839e-5
all_best_mse["edmf_trmm"][(:c, :turbconv, :en, :ρatke)] = 0.0017155449612533727
all_best_mse["edmf_trmm"][(:c, :turbconv, :up, 1, :ρarea)] = 0.0011593753557349142
all_best_mse["edmf_trmm"][(:c, :turbconv, :up, 1, :ρaθ_liq_ice)] = 0.001141776593915803
all_best_mse["edmf_trmm"][(:c, :turbconv, :up, 1, :ρaq_tot)] = 0.001395123961487465
all_best_mse["edmf_trmm"][(:f, :turbconv, :up, 1, :w)] = 0.000389869952029715
#
all_best_mse["compressible_edmf_trmm"] = OrderedCollections.OrderedDict()
all_best_mse["compressible_edmf_trmm"][(:c, :ρ)] = 1.0971360714485972e-13
all_best_mse["compressible_edmf_trmm"][(:c, :ρe_tot)] = 4.7686703459071154e-11
all_best_mse["compressible_edmf_trmm"][(:c, :uₕ, :components, :data, 1)] = 2.552092964252783e-12
all_best_mse["compressible_edmf_trmm"][(:c, :uₕ, :components, :data, 2)] = 6.357904352248731e-11
all_best_mse["compressible_edmf_trmm"][(:c, :ρq_tot)] = 7.619031354895657e-10
all_best_mse["compressible_edmf_trmm"][(:c, :turbconv, :en, :ρatke)] = 5.430395134118745e-8
all_best_mse["compressible_edmf_trmm"][(:c, :turbconv, :up, 1, :ρarea)] = 8.513000777044739e-11
all_best_mse["compressible_edmf_trmm"][(:c, :turbconv, :up, 1, :ρaθ_liq_ice)] = 4.777358877498514e-7
all_best_mse["compressible_edmf_trmm"][(:c, :turbconv, :up, 1, :ρaq_tot)] = 0.00016726707514385037
#
all_best_mse["edmf_gabls"] = OrderedCollections.OrderedDict()
all_best_mse["edmf_gabls"][(:c, :ρ)] = 0.0
all_best_mse["edmf_gabls"][(:c, :ρe_tot)] = 0.0
all_best_mse["edmf_gabls"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["edmf_gabls"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["edmf_gabls"][(:c, :turbconv, :en, :ρatke)] = 0.0
#
all_best_mse["compressible_edmf_gabls"] = OrderedCollections.OrderedDict()
all_best_mse["compressible_edmf_gabls"][(:c, :ρ)] = 5.068448164851311e-27
all_best_mse["compressible_edmf_gabls"][(:c, :ρe_tot)] = 9.75857184411877e-24
all_best_mse["compressible_edmf_gabls"][(:c, :uₕ, :components, :data, 1)] = 3.294125978215983e-23
all_best_mse["compressible_edmf_gabls"][(:c, :uₕ, :components, :data, 2)] = 8.647160988007177e-23
all_best_mse["compressible_edmf_gabls"][(:c, :turbconv, :en, :ρatke)] = 1.552756275112221e-22
#
all_best_mse["single_column_nonorographic_gravity_wave"] = OrderedCollections.OrderedDict()
all_best_mse["single_column_nonorographic_gravity_wave"][(:c, :ρ)] = 0.0
all_best_mse["single_column_nonorographic_gravity_wave"][(:c, :ρe_tot)] = 0.0
all_best_mse["single_column_nonorographic_gravity_wave"][(:c, :uₕ, :components, :data, 1)] = 0.0
all_best_mse["single_column_nonorographic_gravity_wave"][(:c, :uₕ, :components, :data, 2)] = 0.0
all_best_mse["single_column_nonorographic_gravity_wave"][(:f, :w, :components, :data, 1)] = 0.0
#
#! format: on
#################################
#################################
#################################
