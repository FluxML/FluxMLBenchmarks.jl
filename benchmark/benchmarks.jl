using BenchmarkTools
using Random

foreach(println, ENV) # to check environment variables

register_benchmark(env_name::String, benchmark_file::String) =
    get(ENV, env_name, "false") == "true" && include(benchmark_file)

Random.seed!(1234567890)
const SUITE = BenchmarkGroup()

register_benchmark("FLUXML_BENCHMARK_NNLIB", "benchmark/nnlib.jl")
register_benchmark("FLUXML_BENCHMARK_FLUX", "benchmark/flux.jl")
