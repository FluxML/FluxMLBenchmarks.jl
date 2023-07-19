########## conv ############
SUITE["nnlib"]["conv"] = BenchmarkGroup()

SIZES = [
    (3, 256, 3, 1, 1, 1, 1, 0),
    (2, 512, 3, 1, 1, 1, 1, 2),
    (2, 256, 3, 1, 1, 1, 1, 2),
    (1, 512, 3, 1, 1, 1, 1, 0),
    (1, 256, 3, 1, 1, 1, 1, 0),
]
for (rank, N, K, C_in, C_out, stride, dilation, padding) in SIZES
    size_suite = BenchmarkGroup()
    SUITE["nnlib"]["conv"][
        "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
        ] = size_suite

    conv_items = [
        (NNlib.conv_direct!, NNlib.∇conv_data_direct!, NNlib.∇conv_filter_direct!, DenseConvDims, "direct"),
        (NNlib.conv_im2col!, NNlib.∇conv_data_im2col!, NNlib.∇conv_filter_im2col!, DenseConvDims, "im2col"),
        (NNlib.depthwiseconv_direct!, NNlib.∇depthwiseconv_data_direct!, NNlib.∇depthwiseconv_filter_direct!, DepthwiseConvDims, "direct"),
        (NNlib.depthwiseconv_im2col!, NNlib.∇depthwiseconv_data_im2col!, NNlib.∇depthwiseconv_filter_im2col!, DepthwiseConvDims, "im2col"),
    ]

    for (conv!, ∇conv_data!, ∇conv_filter!, cdimT, _) in conv_items
        conv_suite = BenchmarkGroup()
        SUITE["nnlib"]["conv"][
            "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
            ][rstrip(string(conv!), '!')] = conv_suite

        for et in (Float32, Float64)
            et_suite = BenchmarkGroup()
            SUITE["nnlib"]["conv"][
                "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
                ][rstrip(string(conv!), '!')][string(et)] = et_suite

            x = zeros(et, repeat([N], rank)..., C_in, 1)
            w = (cdimT == DenseConvDims) ?
                zeros(et, repeat([K], rank)..., C_in, C_out) :
                zeros(et, repeat([K], rank)..., C_out, C_in)

            cdims = try
                cdimT(x, w; stride = stride, dilation = dilation, padding = padding)
            catch
                continue
            end

            y = (cdimT == DenseConvDims) ?
                zeros(et, NNlib.output_size(cdims)..., C_out, 1) :
                zeros(et, NNlib.output_size(cdims)..., C_out*C_in, 1)

            dx, dy, dw = similar(x), similar(y), similar(w)
            SUITE["nnlib"]["conv"][
                "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
                ][rstrip(string(conv!), '!')][string(et)]["conv"] = @benchmarkable $(conv!)($y, $x, $w, $cdims)
            SUITE["nnlib"]["conv"][
                "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
                ][rstrip(string(conv!), '!')][string(et)]["data"] = @benchmarkable $(∇conv_data!)($dx, $y, $w, $cdims)
            SUITE["nnlib"]["conv"][
                "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
                ][rstrip(string(conv!), '!')][string(et)]["filter"] = @benchmarkable $(∇conv_filter!)($dw, $x, $y, $cdims)
        end
    end
end
