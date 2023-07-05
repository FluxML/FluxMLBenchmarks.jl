using BenchmarkTools
using Random

foreach(println, ENV) # to check environment variables

Random.seed!(1234567890)
const SUITE = BenchmarkGroup()

get(ENV, "FLUXML_BENCHMARK_NNLIB", "false") == "true" &&
    include("benchmark/nnlib.jl")
get(ENV, "FLUXML_BENCHMARK_FLUX", "false") == "true" &&
    include("benchmark/flux.jl")
