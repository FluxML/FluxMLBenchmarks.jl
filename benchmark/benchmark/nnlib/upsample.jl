########## upsample ############
SUITE["nnlib"]["upsample"] = BenchmarkGroup()
SUITE["nnlib"]["upsample"]["linear"] = BenchmarkGroup()
for rank in (3, 2, 1,), et in (Float32, Float16,)
    et_suite = BenchmarkGroup("fw" => BenchmarkGroup(), "bw" => BenchmarkGroup())
    SUITE["nnlib"]["upsample"]["linear"][string(et)] = et_suite

    inputs_sizes = [
        (512, (0.5, 2), false), (256, 8, false),
        (256, 4, true), (128, (1, 2), false), (128, 2, true),
    ]
    for (sz, scale, ac) in inputs_sizes
        x = ones(et, repeat([sz], rank)..., 1, 1)
        et_suite["fw"][
            "$(rank+2)-N($sz)-scale($scale)"
            ] = @benchmarkable upsample_linear($x, $scale; align_corners = $ac)
        et_suite["bw"][
            "$(rank+2)-N($sz)-scale($scale)"
            ] = @benchmarkable ∇upsample_linear($x;
                size = (typeof($scale) <: Tuple) ?
                    floor.(Integer, $sz .* $scale) :
                    ntuple(_ -> floor(Integer, $sz * $scale), $rank),
                align_corners = $ac)
    end
end

SUITE["nnlib"]["upsample"]["nearest"] = BenchmarkGroup()
for rank in (3, 2, 1,), N in (512, 256, 128,)
    et_suite = BenchmarkGroup()
    for et in (Float64, Float32, Float16,)
        x = zeros(Float32, repeat([N], rank)..., 1, 1)
        et_suite[string(et)] = @benchmarkable upsample_nearest($x; size = (repeat([$N * 10], $rank)..., 1, 1))
    end
    SUITE["nnlib"]["upsample"]["nearest"]["$(rank+2)-N($N)"] = et_suite
end
