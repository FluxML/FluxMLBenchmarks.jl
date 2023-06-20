using BenchmarkTools
using Random

Random.seed!(1234567890)
const SUITE = BenchmarkGroup()

include("benchmark/nnlib.jl")
include("benchmark/flux.jl")
