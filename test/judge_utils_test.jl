@testset "judge_utils_test" begin

    @testset "is suitable to use result cache" begin
        dep0 = "Flux"
        dep1 = "NNlib@0.8.20"
        dep2 = "Zygote#2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c"
        dep3 = "https://github.com/FluxML/Optimisers.jl"
        dep4 = "https://github.com/FluxML/Functors.jl#master"
        dep5 = "NNlib@0.8.20,Flux,Zygote#2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c"
        dep6 = "NNlib@0.8.20,Zygote#2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c"
        dep7 = "NNlib@0.8.20,https://github.com/FluxML/Functors.jl#master"
        dep8 = "https://github.com/FluxML/NNlib.jl#36feb3e030b4556925c9de946f334d8460b2627e"

        @test !suitable_to_use_result_cache(dep0)
        @test suitable_to_use_result_cache(dep1)
        @test suitable_to_use_result_cache(dep2)
        @test !suitable_to_use_result_cache(dep3)
        @test !suitable_to_use_result_cache(dep4)
        @test !suitable_to_use_result_cache(dep5)
        @test suitable_to_use_result_cache(dep6)
        @test !suitable_to_use_result_cache(dep7)
        @test suitable_to_use_result_cache(dep8)
    end

end
