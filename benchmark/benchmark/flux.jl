using Flux

model = Chain(
    Flux.flatten,
    Dense(32 * 32, 64, relu),
    Dense(64, 10))

SUITE["flux"] = BenchmarkGroup()
SUITE["flux"]["mlp"] = BenchmarkGroup()
for et in (Float16, Float32, Float64)
    x = rand(et, 32, 32, 1, 5)
    SUITE["flux"]["mlp"][string(et)] = @benchmarkable model($x)
end
