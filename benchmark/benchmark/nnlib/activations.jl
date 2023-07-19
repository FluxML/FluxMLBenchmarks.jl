########## activations ############
SUITE["nnlib"]["activations"] = BenchmarkGroup()
for et in (Float64, Float32, Float16,)
    et_suite = BenchmarkGroup()
    SUITE["nnlib"]["activations"][string(et)] = et_suite
    let x = rand(et, 1024, 1024), y = similar(x)
        for f in NNlib.ACTIVATIONS
            act = @eval($f)
            et_suite[string(f)] = @benchmarkable broadcast!($act, $y, $x)
        end
    end
end
