@testset "env_utils_test" begin

    @testset "Dependency" begin
        flux_dep = Dependency("Flux")
        @test flux_dep.name == "Flux"
        
        nnlib_dep = Dependency("NNlib@0.8.20")
        @test (nnlib_dep.name == "NNlib" && nnlib_dep.version == "0.8.20")
    
        zygote_dep = Dependency("Zygote#2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c")
        @test (zygote_dep.name == "Zygote" && zygote_dep.rev == "2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c")
    
        optimisers_dep = Dependency("https://github.com/FluxML/Optimisers.jl")
        @test optimisers_dep.url == "https://github.com/FluxML/Optimisers.jl"

        functors_dep = Dependency("https://github.com/FluxML/Functors.jl#master")
        @test (functors_dep.url == "https://github.com/FluxML/Functors.jl" && functors_dep.rev == "master")

        onehot_dep = Dependency("https://github.com/FluxML/OneHotArrays.jl@0.2.4")
        @test (onehot_dep.url == "https://github.com/FluxML/OneHotArrays.jl" && onehot_dep.version == "0.2.4")
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

    @testset "parse deps list" begin
        deps_list = "NNlib,https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test;Flux,Flux@0.13.12"
        baseline_deps, target_deps = parse_deps_list(deps_list)
        @test (length(baseline_deps) == 2 &&
               baseline_deps[1].name == "NNlib" &&
               baseline_deps[2].name == "Flux")
        @test (length(target_deps) == 2 &&
               target_deps[1].url == "https://github.com/skyleaworlder/NNlib.jl" &&
               target_deps[1].rev == "dummy-benchmark-test" &&
               target_deps[2].name == "Flux" &&
               target_deps[2].version == "0.13.12")
    end
end