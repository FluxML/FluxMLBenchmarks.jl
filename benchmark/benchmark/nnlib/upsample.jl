########## upsample ############
SUITE["nnlib"]["upsample"] = BenchmarkGroup()
SUITE["nnlib"]["upsample"]["linear"] = BenchmarkGroup()

SIZES = [
    (3, 256, 8, true),
    (3, 128, (1, 2), false),
    (2, 512, (0.5, 2), false),
    (2, 256, 4, false),
    (2, 128, 2, true),
]
for (rank, sz, scale, ac) in SIZES
    et_suite = BenchmarkGroup()
    SUITE["nnlib"]["upsample"]["linear"]["$(rank+2)-N($sz)-scale($scale)"] = et_suite
    for et in (Float32, Float16,)
        et_suite[string(et)] = BenchmarkGroup("fw" => BenchmarkGroup(), "bw" => BenchmarkGroup())
        x = ones(et, repeat([sz], rank)..., 1, 1)
        et_suite[string(et)]["fw"] = @benchmarkable upsample_linear($x, $scale;
                align_corners = $ac)
        et_suite[string(et)]["bw"] = @benchmarkable ∇upsample_linear($x;
                size = (typeof($scale) <: Tuple) ?
                    floor.(Integer, $sz .* $scale) :
                    ntuple(_ -> floor(Integer, $sz * $scale), $rank),
                align_corners = $ac)
    end
end

SUITE["nnlib"]["upsample"]["nearest"] = BenchmarkGroup()
SIZES = [
    (3, 256), (2, 512), (2, 256),
    (1, 512), (1, 256),
]
for (rank, N) in SIZES
    et_suite = BenchmarkGroup()
    for et in (Float64, Float32, Float16,)
        x = zeros(Float32, repeat([N], rank)..., 1, 1)
        et_suite[string(et)] = @benchmarkable upsample_nearest($x; size = (repeat([$N * 10], $rank)..., 1, 1))
    end
    SUITE["nnlib"]["upsample"]["nearest"]["$(rank+2)-N($N)"] = et_suite
end
