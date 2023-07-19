using NNlib
using NNlib.ChainRulesCore: rrule

SUITE["nnlib"] = BenchmarkGroup()

register_benchmark("FLUXML_BENCHMARK_NNLIB_ACTIVATIONS", "nnlib/activations.jl")
register_benchmark("FLUXML_BENCHMARK_NNLIB_SOFTMAX", "nnlib/softmax.jl")
register_benchmark("FLUXML_BENCHMARK_NNLIB_CONV", "nnlib/conv.jl")
register_benchmark("FLUXML_BENCHMARK_NNLIB_POOLING", "nnlib/pooling.jl")
register_benchmark("FLUXML_BENCHMARK_NNLIB_DROPOUT", "nnlib/dropout.jl")
register_benchmark("FLUXML_BENCHMARK_NNLIB_UPSAMPLE", "nnlib/upsample.jl")
register_benchmark("FLUXML_BENCHMARK_NNLIB_GEMM", "nnlib/gemm.jl")
register_benchmark("FLUXML_BENCHMARK_NNLIB_ATTENTION", "nnlib/attention.jl")
