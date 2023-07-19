using Flux

SUITE["flux"] = BenchmarkGroup()

register_benchmark("FLUXML_BENCHMARK_FLUX_MLP", "flux/mlp.jl")
