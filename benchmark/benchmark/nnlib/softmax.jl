########## softmax ############
SUITE["nnlib"]["softmax"] = BenchmarkGroup()
for (fn!, fn_bw) in [(softmax!, NNlib.∇softmax_data), (logsoftmax!, NNlib.∇logsoftmax_data)]
    fn_suite = BenchmarkGroup()
    SUITE["nnlib"]["softmax"][rstrip(string(fn!), '!')] = fn_suite
    let SIZES = [
        (12288, 2048, 1), (4096, 4096, 2), (4096, 2048, 2), (2048, 2048, 2),
        (1024, 2048, 4), (768, 1024, 4), (512, 784, 8), (128, 384, 8),
    ]
        for et in (Float32, Float16,)
            et_suite = BenchmarkGroup("fw" => BenchmarkGroup(), "bw" => BenchmarkGroup())
            fn_suite[string(et)] = et_suite
            for sz in SIZES
                x = randn(et, sz)
                y = similar(x)
                dy = zero(x)
                fn!(y, x)
                et_suite["fw"][string(sz)] = @benchmarkable $fn!($y, $x)
                et_suite["bw"][string(sz)] = @benchmarkable $fn_bw($dy, $y)
            end
        end
    end
end
