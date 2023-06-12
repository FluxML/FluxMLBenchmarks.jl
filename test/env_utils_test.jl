@testset "env_utils_test" begin

    @testset "Dependency" begin
        flux_dep = Dependency(name = "Flux")
        @test flux_dep.name == "Flux"
        
        nnlib_dep = Dependency(name = "NNlib", version = "0.8.20")
        @test (nnlib_dep.name == "NNlib" && nnlib_dep.version == "0.8.20")
    
        zygote_dep = Dependency(name = "Zygote", rev = "2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c")
        @test (zygote_dep.name == "Zygote" && zygote_dep.rev == "2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c")
    
        optimisers_dep = Dependency(url = "https://github.com/FluxML/Optimisers.jl")
        @test optimisers_dep.url == "https://github.com/FluxML/Optimisers.jl" 
    end

    @testset "dependency operation" begin
        init_deps = init_dependencies()
        @test length(init_deps) == 10

        nnlib_dep = Dependency(name = "NNlib", version = "0.8.20")
        fixed_deps = init_dependencies(Vector([nnlib_dep]))
        is_tested = false
        for (dep_name, pkg_spec) in fixed_deps if dep_name == "NNlib"
            @test pkg_spec.version == "0.8.20"
            is_tested = true
        end end
        @test is_tested
    end

end