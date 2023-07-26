using BenchmarkTools
using Random

foreach(println, ENV) # to check environment variables

register_benchmark(env_name::String, benchmark_file::String) =
    get(ENV, env_name, "false") == "true" && (
        @info "Begin to @benchmarkable $benchmark_file";    
        include(benchmark_file);
        @info "End   to @benchmarkable $benchmark_file"
    )

Random.seed!(1234567890)
const SUITE = BenchmarkGroup()

BenchmarkTools.DEFAULT_PARAMETERS.samples = 20
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 2.5
BenchmarkTools.DEFAULT_PARAMETERS.gcsample = true

register_benchmark("FLUXML_BENCHMARK_NNLIB", "benchmark/nnlib.jl")
register_benchmark("FLUXML_BENCHMARK_FLUX", "benchmark/flux.jl")
