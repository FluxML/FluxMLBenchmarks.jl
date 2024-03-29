@testset "env_utils_test" begin

    @testset "check benchmark location" begin
        @test BENCHMARK_PKG_PATH == "./benchmark"
        @test BENCHMARK_FILES_PATH == "./benchmark/benchmark"
    end

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
        @test length(init_deps) == 9

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
        deps_list = "NNlib,Flux;https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test,Flux@0.13.12"
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

    @testset "parse enabled benchmarks" begin
        cd("..") # return to the top dir

        default_enable = reduce((x,y) -> "$x;$y", FLUXML_AVAILABLE_TOP_LEVEL_BENCHMARKS)
        default_disable = ""
        eb0 = parse_enabled_benchmarks(default_enable, default_disable)
        @test length(eb0) == 11     # flux(2), nnlib(9)

        disable0 = "nnlib;flux"
        eb1 = parse_enabled_benchmarks(default_enable, disable0)
        @test length(eb1) == 2      # flux(1), nnlib(1)

        enable0 = "flux;nnlib;zygote"
        eb2 = parse_enabled_benchmarks(enable0, default_disable)
        @test length(eb2) == 11     # flux(2), nnlib(9)
        @test get(eb2, "FLUXML_BENCHMARK_FLUX", false) &&
                get(eb2, "FLUXML_BENCHMARK_NNLIB", false) &&
                !get(eb2, "FLUXML_BENCHMARK_ZYGOTE", false)

        enable1 = "flux;nnlib;zygote"
        disable1 = "zygote;flux"
        eb3 = parse_enabled_benchmarks(enable1, disable1)
        @test length(eb3) == 10      # flux(1), nnlib(9)
        @test get(eb3, "FLUXML_BENCHMARK_FLUX", false) &&
                !get(eb3, "FLUXML_BENCHMARK_ZYGOTE", false) &&
                get(eb3, "FLUXML_BENCHMARK_NNLIB", false)

        disable2 = "flux;not_existed_package;unknown_package"
        eb4 = parse_enabled_benchmarks(default_enable, disable2)
        @test length(eb4) == 10      # flux(1), nnlib(9)
        @test get(eb3, "FLUXML_BENCHMARK_FLUX", false)

        enable2 = "flux;nnlib(activations)"
        eb5 = parse_enabled_benchmarks(enable2, "")
        @test length(eb5) == 4      # flux(2), nnlib(2)

        enable3 = "flux;nnlib(gemm,conv)"
        disable3 = "nnlib(conv)"
        eb6 = parse_enabled_benchmarks(enable3, disable3)
        @test length(eb6) == 4      # flux(2), nnlib(2)

        disable4 = "flux;nnlib"
        eb8 = parse_enabled_benchmarks(enable3, disable4)
        @test length(eb8) == 2      # flux(1), nnlib(1)
    end
end