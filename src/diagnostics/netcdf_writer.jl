# netcdf_writer.jl
#
# The flow of the code is:
#
# - We define a generic NetCDF struct with the NetCDF constructor. In doing this, we check
#   what we have to do for topography. We might have to interpolate it or not so that we can
#   later provide the correct elevation profile.

# - The first time write_fields! is called with the writer on a new field, we add the
#   dimensions to the NetCDF file. This requires understanding what coordinates we have to
#   interpolate on and potentially handle topography.
#
#   The functions to do so are for the most part all methods of the same functions, so that
#   we can achieve the same behavior for different types of configurations (planes/spheres,
#   ...), but also different types of fields (horizontal ones, 3D ones, ...)
#

################
# NetCDFWriter #
################
"""
    add_dimension_maybe!(nc::NCDatasets.NCDataset,
                         name::String,
                         points;
                         kwargs...)


Add dimension identified by `name` in the given `nc` file and fill it with the given
`points`. If the dimension already exists, check if it is consistent with the new one.
Optionally, add all the keyword arguments as attributes.
"""

function add_dimension_maybe!(
    nc::NCDatasets.NCDataset,
    name::String,
    points;
    kwargs...,
)
    FT = eltype(points)

    if haskey(nc, name)
        # dimension already exists: check correct size
        if size(nc[name]) != size(points)
            error("Incompatible $name dimension already exists")
        end
    else
        NCDatasets.defDim(nc, name, size(points)[end])

        dim = NCDatasets.defVar(nc, name, FT, (name,))
        for (k, v) in kwargs
            dim.attrib[String(k)] = v
        end

        dim[:] = points
    end
    return nothing
end

"""
    add_time_maybe!(nc::NCDatasets.NCDataset,
                    float_type::DataType;
                    kwargs...)


Add the `time` dimension (with infinite size) to the given NetCDF file if not already there.
Optionally, add all the keyword arguments as attributes.
"""
function add_time_maybe!(
    nc::NCDatasets.NCDataset,
    float_type::DataType;
    kwargs...,
)

    # If we already have time, do nothing
    haskey(nc, "time") && return nothing

    NCDatasets.defDim(nc, "time", Inf)
    dim = NCDatasets.defVar(nc, "time", float_type, ("time",))
    for (k, v) in kwargs
        dim.attrib[String(k)] = v
    end
    return nothing
end

"""
    add_space_coordinates_maybe!(nc::NCDatasets.NCDataset,
                                 space::Spaces.AbstractSpace,
                                 num_points;
                                 names)

Add dimensions relevant to the `space` to the given `nc` NetCDF file. The range is
automatically determined and the number of points is set with `num_points`, which has to be
an iterable of size N, where N is the number of dimensions of the space. For instance, 3 for
a cubed sphere, 2 for a surface, 1 for a column.

The function returns an array with the names of the relevant dimensions. (We want arrays
because we want to preserve the order to match the one in num_points).

In some cases, the names are adjustable passing the keyword `names`.
"""
function add_space_coordinates_maybe! end

"""
    target_coordinates!(space::Spaces.AbstractSpace,
                        num_points)

Return the range of interpolation coordinates. The range is automatically determined and the
number of points is set with `num_points`, which has to be an iterable of size N, where N is
the number of dimensions of the space. For instance, 3 for a cubed sphere, 2 for a surface,
1 for a column.
"""
function target_coordinates(space, num_points) end

function target_coordinates(
    space::S,
    num_points,
) where {
    S <:
    Union{Spaces.CenterFiniteDifferenceSpace, Spaces.FaceFiniteDifferenceSpace},
}
    # Exponentially spaced with base e
    #
    # We mimic something that looks like pressure levels
    #
    # p ~ p₀ exp(-z/H)
    #
    # We assume H to be 7000, which is a good scale height for the Earth atmosphere
    H_EARTH = 7000

    num_points_z = num_points[]
    FT = Spaces.undertype(space)
    topology = Spaces.topology(space)
    vert_domain = topology.mesh.domain
    z_min, z_max = FT(vert_domain.coord_min.z), FT(vert_domain.coord_max.z)
    # We floor z_min to avoid having to deal with the singular value z = 0.
    z_min = max(z_min, 100)
    exp_z_min = exp(-z_min / H_EARTH)
    exp_z_max = exp(-z_max / H_EARTH)
    return collect(-H_EARTH * log.(range(exp_z_min, exp_z_max, num_points_z)))
end

# Column
function add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space::Spaces.FiniteDifferenceSpace,
    num_points_z;
    names = ("z",),
)
    name, _... = names
    zpts = target_coordinates(space, num_points_z)
    add_dimension_maybe!(nc, name, zpts, units = "m", axis = "Z")
    return [name]
end

add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space::Spaces.AbstractSpectralElementSpace,
    num_points;
) = add_space_coordinates_maybe!(
    nc,
    space,
    num_points,
    Meshes.domain(Spaces.topology(space));
)


# For the horizontal space, we also have to look at the domain, so we define another set of
# functions that dispatches over the domain
target_coordinates(space::Spaces.AbstractSpectralElementSpace, num_points) =
    target_coordinates(space, num_points, Meshes.domain(Spaces.topology(space)))

# Box
function target_coordinates(
    space::Spaces.SpectralElementSpace2D,
    num_points,
    domain::Domains.RectangleDomain,
)
    num_points_x, num_points_y = num_points
    FT = Spaces.undertype(space)
    xmin = FT(domain.interval1.coord_min.x)
    xmax = FT(domain.interval1.coord_max.x)
    ymin = FT(domain.interval2.coord_min.y)
    ymax = FT(domain.interval2.coord_max.y)
    xpts = collect(range(xmin, xmax, num_points_x))
    ypts = collect(range(ymin, ymax, num_points_y))
    return (xpts, ypts)
end

# Plane
function target_coordinates(
    space::Spaces.SpectralElementSpace1D,
    num_points,
    domain::Domains.IntervalDomain,
)
    num_points_x, _... = num_points
    FT = Spaces.undertype(space)
    xmin = FT(domain.coord_min.x)
    xmax = FT(domain.coord_max.x)
    xpts = collect(range(xmin, xmax, num_points_x))
    return (xpts)
end

# Cubed sphere
function target_coordinates(
    space::Spaces.SpectralElementSpace2D,
    num_points,
    ::Domains.SphereDomain,
)
    num_points_long, num_points_lat = num_points
    FT = Spaces.undertype(space)
    longpts = collect(range(FT(-180), FT(180), num_points_long))
    latpts = collect(range(FT(-80), FT(80), num_points_lat))

    return (longpts, latpts)
end

# Box
function add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space::Spaces.SpectralElementSpace2D,
    num_points,
    ::Domains.RectangleDomain;
    names = ("x", "y"),
)
    xname, yname = names
    xpts, ypts = target_coordinates(space, num_points)
    add_dimension_maybe!(nc, "x", xpts; units = "m", axis = "X")
    add_dimension_maybe!(nc, "y", ypts; units = "m", axis = "Y")
    return [xname, yname]
end

# Plane
function add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space::Spaces.SpectralElementSpace1D,
    num_points,
    ::Domains.IntervalDomain;
    names = ("x",),
)
    xname, _... = names
    xpts = target_coordinates(space, num_points)
    add_dimension_maybe!(nc, "x", xpts; units = "m", axis = "X")
    return [xname]
end

# Cubed sphere
function add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space::Spaces.SpectralElementSpace2D,
    num_points,
    ::Domains.SphereDomain;
    names = ("lon", "lat"),
)
    longname, latname = names
    longpts, latpts = target_coordinates(space, num_points)
    add_dimension_maybe!(nc, "lon", longpts; units = "degrees_east", axis = "X")
    add_dimension_maybe!(nc, "lat", latpts; units = "degrees_north", axis = "Y")
    return [longname, latname]
end

# General hybrid space. This calls both the vertical and horizontal add_space_coordinates_maybe!
# and combines the resulting dictionaries
function add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space::Spaces.ExtrudedFiniteDifferenceSpace,
    num_points;
    interpolated_surface = nothing,
)

    hdims_names = vdims_names = []

    num_points_horiz..., num_points_vertic = num_points

    # Being an Extruded space, we can assume that we have an horizontal and a vertical space.
    # We can also assume that the vertical space has dimension 1
    horizontal_space = Spaces.horizontal_space(space)

    hdims_names =
        add_space_coordinates_maybe!(nc, horizontal_space, num_points_horiz)

    vertical_space = Spaces.FiniteDifferenceSpace(
        Spaces.vertical_topology(space),
        Spaces.staggering(space),
    )

    if isnothing(interpolated_surface)
        vdims_names =
            add_space_coordinates_maybe!(nc, vertical_space, num_points_vertic)
    else
        vdims_names = add_space_coordinates_maybe!(
            nc,
            vertical_space,
            num_points_vertic,
            interpolated_surface;
            names = ("z_reference",),
            depending_on_dimensions = hdims_names,
        )
    end

    return (hdims_names..., vdims_names...)
end

# Ignore the interpolated_surface/disable_vertical_interpolation keywords in the general
# case (we only case about the specialized one for extruded spaces)
add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space,
    num_points;
    interpolated_surface = nothing,
    disable_vertical_interpolation = false,
) = add_space_coordinates_maybe!(nc::NCDatasets.NCDataset, space, num_points)

# Elevation with topography

# `depending_on_dimensions` identifies the dimensions upon which the current one depends on
# (excluding itself). In pretty much all cases, the dimensions depend only on themselves
# (e.g., `lat` is a variable only defined on the latitudes.), and `depending_on_dimensions`
# should be an empty tuple. The only case in which this is not what happens is with `z` with
# topography. With topography, the altitude will depend on the spatial coordinates. So,
# `depending_on_dimensions` might be `("lon", "lat)`, or similar.
function add_space_coordinates_maybe!(
    nc::NCDatasets.NCDataset,
    space::Spaces.FiniteDifferenceSpace,
    num_points,
    interpolated_surface;
    names = ("z_reference",),
    depending_on_dimensions,
)
    num_points_z = num_points
    name, _... = names

    # Implement the LinearAdaption hypsography
    reference_altitudes = target_coordinates(space, num_points_z)

    add_dimension_maybe!(nc, name, reference_altitudes; units = "m", axis = "Z")

    z_top = Spaces.topology(space).mesh.domain.coord_max.z

    # Prepare output array
    desired_shape = (size(interpolated_surface)..., num_points_z)
    zpts = zeros(eltype(interpolated_surface), desired_shape)

    for i in CartesianIndices(interpolated_surface)
        z_surface = interpolated_surface[i]
        @. zpts[i, :] +=
            reference_altitudes + (1 .- reference_altitudes / z_top) * z_surface
    end

    # We also have to add an extra variable with the physical altitudes
    physical_name = "z_physical"
    if !haskey(nc, physical_name)
        FT = eltype(zpts)
        dim = NCDatasets.defVar(
            nc,
            physical_name,
            FT,
            (depending_on_dimensions..., name),
        )
        dim.attrib["units"] = "m"
        dim[:, :, :] = zpts
    end

    return [name]
end

# General hybrid space. This calls both the vertical and horizontal add_space_coordinates_maybe!
# and combines the resulting dictionaries
function target_coordinates(
    space::Spaces.ExtrudedFiniteDifferenceSpace,
    num_points,
)

    hcoords = vcoords = ()

    num_points_horiz..., num_points_vertic = num_points

    hcoords =
        target_coordinates(Spaces.horizontal_space(space), num_points_horiz)

    vertical_space = Spaces.FiniteDifferenceSpace(
        Spaces.vertical_topology(space),
        Spaces.staggering(space),
    )
    vcoords = target_coordinates(vertical_space, num_points_vertic)

    hcoords == vcoords == () && error("Found empty space")

    return hcoords, vcoords
end

function hcoords_from_horizontal_space(
    space::Spaces.SpectralElementSpace2D,
    domain::Domains.SphereDomain,
    hpts,
)
    # Notice LatLong not LongLat!
    return [Geometry.LatLongPoint(hc2, hc1) for hc1 in hpts[1], hc2 in hpts[2]]
end

function hcoords_from_horizontal_space(
    space::Spaces.SpectralElementSpace2D,
    domain::Domains.RectangleDomain,
    hpts,
)
    return [Geometry.XYPoint(hc1, hc2) for hc1 in hpts[1], hc2 in hpts[2]]
end

function hcoords_from_horizontal_space(
    space::Spaces.SpectralElementSpace1D,
    domain::Domains.IntervalDomain,
    hpts,
)
    return [Geometry.XPoint(hc1) for hc1 in hpts]
end

"""
    hcoords_from_horizontal_space(space, domain, hpts)

Prepare the matrix of horizontal coordinates with the correct type according to the given `space`
and `domain` (e.g., `ClimaCore.Geometry.LatLongPoint`s).
"""
function hcoords_from_horizontal_space(space, domain, hpts) end

struct NetCDFWriter{T, TS}

    # TODO: At the moment, each variable gets its remapper. This is a little bit of a waste
    # because we probably only need a handful of remappers since the same remapper can be
    # used for multiple fields as long as they are all defined on the same space. We need
    # just a few remappers because realistically we need to support fields defined on the
    # entire space and fields defined on 2D slices. However, handling this distinction at
    # construction time is quite difficult.
    remappers::Dict{String, Remapper}

    # Tuple/Array of integers that identifies how many points to use for interpolation along
    # the various dimensions. It has to have the same size as the target interpolation
    # space.
    num_points::T

    # How much to compress the data in the final NetCDF file: 0 no compression, 9 max
    # compression.
    compression_level::Int

    # nothing, if z is the altitude from the sea level (ie, no topography, or topography
    # already interpolated). Otherwise, a 1/2D array that describes the surface elevation
    # interpolated on the horizontal points.
    interpolated_surface::TS

    # NetCDF files that are currently open. Only the root process uses this field.
    open_files::Dict{String, NCDatasets.NCDataset}

    # Whether to treat z as altitude over the surface or the sea level or over the surface
    interpolate_z_over_msl::Bool

    # Do not interpolate on the z direction, instead evaluate on the levels.
    # This is incompatible with interpolate_z_over_msl when topography is present.
    # When disable_vertical_interpolation is true, the num_points on the vertical direction
    # is ignored.
    disable_vertical_interpolation::Bool
end

"""
    close(writer::NetCDFWriter)


Close all the files open in `writer`.
"""
close(writer::NetCDFWriter) = map(NCDatasets.close, values(writer.open_files))

"""
    NetCDFWriter()


Save a `ScheduledDiagnostic` to a NetCDF file inside the `output_dir` of the simulation by
performing a pointwise (non-conservative) remapping first.

Keyword arguments
==================

- `num_points`: How many points to use along the different dimensions to interpolate the
                fields. This is a tuple of integers, typically having meaning Long-Lat-Z,
                or X-Y-Z (the details depend on the configuration being simulated).
- `interpolate_z_over_msl`: When `true`, the variable `z` is intended to be altitude from
                            the sea level (in meters). Values of `z` that are below the
                            surface are filled with `NaN`s. When `false`, `z` is intended to
                            be altitude from the surface (in meters). `z` becomes a
                            multidimensional array that returns the altitude for the given
                            horizontal coordinates.
- `disable_vertical_interpolation`: Do not interpolate on the z direction, instead evaluate
                                    at on levels. This is incompatible with
                                    interpolate_z_over_msl when topography is present. When
                                    disable_vertical_interpolation is true, the num_points
                                    on the vertical direction is ignored.
- `compression_level`: How much to compress the output NetCDF file (0 is no compression, 9
  is maximum compression).

"""
function NetCDFWriter(;
    spaces,
    num_points = (180, 90, 50),
    interpolate_z_over_msl = false,
    disable_vertical_interpolation = false,
    compression_level = 9,
)
    space = spaces.center_space
    hypsography = Spaces.grid(space).hypsography

    # When we are interpolating on the vertical direction, we have to deal with the pesky
    # topography. This is a little annoying to deal with because it couples the horizontal
    # and the vertical dimensions, so it doesn't fit the common paradigm for all the other
    # dimensions. Moreover, with topography, we need to perform an interpolation for the
    # surface.

    # We have to deal with the surface only if we are not interpolating the topography and
    # if our topography is non-trivial
    if hypsography isa Grids.Flat || interpolate_z_over_msl
        interpolated_surface = nothing
    else
        horizontal_space = axes(hypsography.surface)
        hpts = target_coordinates(horizontal_space, num_points)
        hcoords = hcoords_from_horizontal_space(
            horizontal_space,
            Spaces.topology(horizontal_space).mesh.domain,
            hpts,
        )
        vcoords = []
        remapper = Remapper(hcoords, vcoords, horizontal_space)
        interpolated_surface =
            interpolate(remapper, hypsography.surface, physical_z = false)
    end

    if disable_vertical_interpolation
        # It is a little tricky to override the number of vertical points because we don't
        # know if the vertical direction is the 2nd (as in a plane) or 3rd index (as in a
        # box or sphere). To set this value, we check if we are on a plane or not

        # TODO: Get the number of dimensions directly from the space
        num_horiz_dimensions =
            Spaces.horizontal_space(space) isa Spaces.SpectralElementSpace1D ?
            1 : 2

        num_vpts = Meshes.nelements(Grids.vertical_topology(space).mesh)

        @warn "Disabling vertical interpolation, the provided number of points is ignored (using $num_vpts)"
        num_points = Tuple([num_points[1:num_horiz_dimensions]..., num_vpts])
    end

    return NetCDFWriter{typeof(num_points), typeof(interpolated_surface)}(
        Dict(),
        num_points,
        compression_level,
        interpolated_surface,
        Dict(),
        interpolate_z_over_msl,
        disable_vertical_interpolation,
    )
end

function write_field!(
    writer::NetCDFWriter,
    field,
    diagnostic,
    integrator,
    output_dir,
)

    var = diagnostic.variable

    space = axes(field)
    FT = Spaces.undertype(space)

    horizontal_space = Spaces.horizontal_space(space)

    # We have to deal with to cases: when we have an horizontal slice (e.g., the
    # surface), and when we have a full space. We distinguish these cases by checking if
    # the given space has the horizontal_space attribute. If not, it is going to be a
    # SpectralElementSpace2D and we don't have to deal with the z coordinates.
    is_horizontal_space = horizontal_space == space

    # Prepare the remapper if we don't have one for the given variable. We need one remapper
    # per variable (not one per diagnostic since all the time reductions return the same
    # type of space).

    # TODO: Expand this once we support spatial reductions
    if !haskey(writer.remappers, var.short_name)

        # hpts, vpts are ranges of numbers
        # hcoords, zcoords are ranges of Geometry.Points

        zcoords = []

        if is_horizontal_space
            hpts = target_coordinates(space, writer.num_points)
            vpts = []
        else
            hpts, vpts = target_coordinates(space, writer.num_points)
        end

        hcoords = hcoords_from_horizontal_space(
            horizontal_space,
            Meshes.domain(Spaces.topology(horizontal_space)),
            hpts,
        )

        # When we disable vertical_interpolation, we override the vertical points with
        # the reference values for the vertical space.
        if writer.disable_vertical_interpolation && !is_horizontal_space
            # We need Array(parent()) because we want an array of values, not a DataLayout
            # of Points
            vpts = Array(
                parent(
                    space.grid.vertical_grid.center_local_geometry.coordinates,
                ),
            )
        end

        zcoords = [Geometry.ZPoint(p) for p in vpts]

        writer.remappers[var.short_name] = Remapper(hcoords, zcoords, space)
    end

    remapper = writer.remappers[var.short_name]

    # Now we can interpolate onto the target points
    # There's an MPI call in here (to aggregate the results)
    interpolated_field =
        interpolate(remapper, field; physical_z = writer.interpolate_z_over_msl)

    # Only the root process has to write
    ClimaComms.iamroot(ClimaComms.context(field)) || return

    output_path = joinpath(output_dir, "$(diagnostic.output_short_name).nc")

    if !haskey(writer.open_files, output_path)
        # Append or write a new file
        open_mode = isfile(output_path) ? "a" : "c"
        writer.open_files[output_path] =
            NCDatasets.Dataset(output_path, open_mode)
    end

    nc = writer.open_files[output_path]

    # Define time coordinate
    add_time_maybe!(nc, FT; units = "s", axis = "T")

    dim_names = add_space_coordinates_maybe!(
        nc,
        space,
        writer.num_points;
        writer.interpolated_surface,
    )

    if haskey(nc, "$(var.short_name)")
        # We already have something in the file
        v = nc["$(var.short_name)"]
        temporal_size, spatial_size... = size(v)
        spatial_size == size(interpolated_field) ||
            error("incompatible dimensions for $(var.short_name)")
    else
        v = NCDatasets.defVar(
            nc,
            "$(var.short_name)",
            FT,
            ("time", dim_names...),
            deflatelevel = writer.compression_level,
        )
        v.attrib["short_name"] = var.short_name
        v.attrib["long_name"] = diagnostic.output_long_name
        v.attrib["short_name"] = var.short_name
        v.attrib["units"] = var.units
        v.attrib["comments"] = var.comments

        temporal_size = 0
    end

    # We need to write to the next position after what we read from the data (or the first
    # position ever if we are writing the file for the first time)
    time_index = temporal_size + 1

    nc["time"][time_index] = integrator.t

    # TODO: It would be nice to find a cleaner way to do this
    if length(dim_names) == 3
        v[time_index, :, :, :] = interpolated_field
    elseif length(dim_names) == 2
        v[time_index, :, :] = interpolated_field
    elseif length(dim_names) == 1
        v[time_index, :] = interpolated_field
    end

    # Write data to disk
    NCDatasets.sync(writer.open_files[output_path])
end
