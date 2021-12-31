@testset "Domains" begin
    for FT in float_types
        domain = Column(FT, zlim = (-1, π), nelements = 2)
        @test domain.zlim == FT.((-1, π))
        @test domain.nelements == 2
        @test make_function_space(domain) isa Tuple{
            Spaces.CenterFiniteDifferenceSpace,
            Spaces.FaceFiniteDifferenceSpace,
        }

        domain = HybridPlane(
            FT,
            xlim = (-1, π),
            zlim = (-2, 2π),
            nelements = (2, 3),
            npolynomial = 4,
            xperiodic = false,
        )
        @test domain.xlim == FT.((-1, π))
        @test domain.zlim == FT.((-2, 2π))
        @test domain.nelements == (2, 3)
        @test domain.npolynomial == 4
        @test domain.xperiodic == false
        @test make_function_space(domain) isa Tuple{
            Spaces.CenterExtrudedFiniteDifferenceSpace,
            Spaces.FaceExtrudedFiniteDifferenceSpace,
        }
    end
end
