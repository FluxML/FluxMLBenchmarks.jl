########## dropout ############
SUITE["nnlib"]["dropout"] = BenchmarkGroup()
for rank in (1, 2, 3,), N in (128, 512, 1024,)
    size_suite = BenchmarkGroup()
    SUITE["nnlib"]["dropout"]["$(rank+2)-N($N)"] = size_suite

    x = ones(Float32, repeat([N], rank)..., 1, 1)
    y = zeros(Float32, repeat([N], rank)..., 1, 1)
    p = 0.2

    dropout_suite = BenchmarkGroup()
    dropout_suite["with-colon"] = @benchmarkable dropout($x, $p)
    dropout_suite["with-dim"] = @benchmarkable dropout($x, $p; dims = 1)
    SUITE["nnlib"]["dropout"]["$(rank+2)-N($N)"]["dropout"] = dropout_suite

    dropout!_suite = BenchmarkGroup()
    dropout!_suite["with-colon"] = @benchmarkable dropout!($y, $x, $p)
    dropout!_suite["with-dim"] = @benchmarkable dropout!($y, $x, $p; dims = 1)
    SUITE["nnlib"]["dropout"]["$(rank+2)-N($N)"]["dropout!"] = dropout!_suite
end
