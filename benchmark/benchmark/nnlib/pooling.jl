########## pooling ############
SUITE["nnlib"]["pooling"] = BenchmarkGroup()
SIZES = [
    (3, 256, 4, 4), (3, 256, 2, 1),
    (2, 512, 4, 4), (2, 512, 4, 2), (2, 512, 4, 1), (2, 512, 2, 4),
    (2, 256, 4, 4), (2, 256, 2, 2), (2, 256, 2, 1),
    (1, 512, 4, 4), (1, 512, 2, 4), (1, 512, 4, 2),
    (1, 256, 4, 4), (1, 256, 2, 4), (1, 256, 4, 2),
]
for (rank, N, K, stride) in SIZES
    size_suite = BenchmarkGroup()
    SUITE["nnlib"]["pooling"]["$(rank+2)-N($N)-K($K)-stride($stride)"] = size_suite

    x = zeros(Float32, repeat([N], rank)..., 1, 1)
    pdims = PoolDims(x, K; stride = stride)
    y = zeros(Float32, NNlib.output_size(pdims)..., 1, 1)
    dx, dy = similar(x), similar(y)

    pooling_items = [
        (NNlib.maxpool!, NNlib.∇maxpool!, "maxpool"),
        (NNlib.meanpool!, NNlib.∇meanpool!, "meanpool"),
        (NNlib.lpnormpool!, NNlib.∇lpnormpool!, "lpnormpool"),
    ]

    for (pool, ∇pool, name) in pooling_items
        pooling_suite = BenchmarkGroup()
        SUITE["nnlib"]["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["$(name)$(rank)d-direct"] = pooling_suite
        SUITE["nnlib"]["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["$(name)$(rank)d-direct"]["pool"] = @benchmarkable $pool(
                $y, $x, $pdims; p = ($name == "lpnormpool") ? 2 : nothing)
        SUITE["nnlib"]["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["$(name)$(rank)d-direct"]["data"] = @benchmarkable $(∇pool)(
                $dx, $dy, $y, $x, $pdims; p = ($name == "lpnormpool") ? 2 : nothing)
    end

    if NNlib.is_nnpack_available() && NNlib.nnpack_supported_operation(pdims)
        SUITE["nnlib"]["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["maxpool$(rank)d-nnpack"]["pool"] = @benchmarkable NNlib.maxpool_nnpack!($y, $x, $pdims)
    end
end
