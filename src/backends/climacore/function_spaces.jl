function create_function_space(::ClimaCoreBackend, ::AbstractDomain)
    error("Domain not supported by ClimaCoreBackend.")
end

function create_function_space(::ClimaCoreBackend, domain::Rectangle)
    rectangle = Domains.RectangleDomain(
        domain.xlim,
        domain.ylim,
        x1periodic = domain.periodic[1],
        x2periodic = domain.periodic[2],
    )
    mesh = Meshes.EquispacedRectangleMesh(
        rectangle, 
        domain.nelements[1], 
        domain.nelements[2]
    )
    grid_topology = Topologies.GridTopology(mesh)
    quad = Spaces.Quadratures.GLL{domain.npolynomial}()
    function_space = Spaces.SpectralElementSpace2D(grid_topology, quad)

    return function_space
end

function create_function_space(::ClimaCoreBackend, domain::SingleColumn)
    column = Domains.IntervalDomain(
        domain.zlim[1], 
        domain.zlim[2]; 
        x3boundary = (:bottom, :top)
    )
    mesh = Meshes.IntervalMesh(column; nelems = domain.nelems)

    center_space = Spaces.CenterFiniteDifferenceSpace(mesh)
    face_space = Spaces.FaceFiniteDifferenceSpace(center_space)

    return center_space, face_space
end