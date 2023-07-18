########## mlp ############
SUITE["flux"]["mlp"] = BenchmarkGroup()

model = Chain(
    Flux.flatten,
    Dense(32 * 32, 64, relu),
    Dense(64, 10))

for et in (Float16, Float32, Float64)
    x = rand(et, 32, 32, 1, 5)
    SUITE["flux"]["mlp"][string(et)] = @benchmarkable model($x)
end
