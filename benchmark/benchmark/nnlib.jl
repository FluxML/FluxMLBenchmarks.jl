using NNlib
using NNlib.ChainRulesCore: rrule
using Random

########## activations ############
SUITE["activations"] = BenchmarkGroup()
for et in (Float16, Float32, Float64)
    et_suite = BenchmarkGroup()
    SUITE["activations"][string(et)] = et_suite
    let x = rand(et, 1024, 1024), y = similar(x)
        for f in NNlib.ACTIVATIONS
            act = @eval($f)
            et_suite[string(f)] = @benchmarkable broadcast!($act, $y, $x)
        end
    end
end


########## softmax ############
SUITE["softmax"] = BenchmarkGroup()
for (fn!, fn_bw) in [(softmax!, NNlib.∇softmax_data), (logsoftmax!, NNlib.∇logsoftmax_data)]
    fn_suite = BenchmarkGroup()
    SUITE["softmax"][rstrip(string(fn!), '!')] = fn_suite
    let SIZES = [
        (128, 384, 8), (512, 784, 8), (768, 1024, 4), (1024, 2048, 4),
        (2048, 2048, 2), (4096, 2048, 2), (4096, 4096, 2), (12288, 2048, 1)
    ]
        for et in (Float16, Float32)
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


########## conv ############
SUITE["conv"] = BenchmarkGroup()
for rank in (1, 2, 3,), N in (20,), K in (3,),
    C_in in (1,), C_out in (1,),
    stride in (1,), dilation in (1,), padding in (0,2)

    size_suite = BenchmarkGroup()
    SUITE["conv"][
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
        SUITE["conv"][
            "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
            ][rstrip(string(conv!), '!')] = conv_suite

        for et in (Float32, Float64)
            et_suite = BenchmarkGroup()
            SUITE["conv"][
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
            SUITE["conv"][
                "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
                ][rstrip(string(conv!), '!')][string(et)]["conv"] = @benchmarkable $(conv!)($y, $x, $w, $cdims)
            SUITE["conv"][
                "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
                ][rstrip(string(conv!), '!')][string(et)]["data"] = @benchmarkable $(∇conv_data!)($dx, $y, $w, $cdims)
            SUITE["conv"][
                "$(rank+2)-N($N)-K($K)-in($C_in)-out($C_out)-stride($stride)-dilation($dilation)-padding($padding)"
                ][rstrip(string(conv!), '!')][string(et)]["filter"] = @benchmarkable $(∇conv_filter!)($dw, $x, $y, $cdims)
        end
    end
end


########## pooling ############
SUITE["pooling"] = BenchmarkGroup()
for rank in (2,), N in (20, ), K in (2, 4,), stride in (1, 2, 4)
    size_suite = BenchmarkGroup()
    SUITE["pooling"]["$(rank+2)-N($N)-K($K)-stride($stride)"] = size_suite

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
        SUITE["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["$(name)$(rank)d-direct"] = pooling_suite
        SUITE["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["$(name)$(rank)d-direct"]["pool"] = @benchmarkable $pool(
                $y, $x, $pdims; p = ($name == "lpnormpool") ? 2 : nothing)
        SUITE["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["$(name)$(rank)d-direct"]["data"] = @benchmarkable $(∇pool)(
                $dx, $dy, $y, $x, $pdims; p = ($name == "lpnormpool") ? 2 : nothing)
    end

    if NNlib.is_nnpack_available() && NNlib.nnpack_supported_operation(pdims)
        SUITE["pooling"][
            "$(rank+2)-N($N)-K($K)-stride($stride)"
            ]["maxpool$(rank)d-nnpack"]["pool"] = @benchmarkable NNlib.maxpool_nnpack!($y, $x, $pdims)
    end
end


########## dropout ############
SUITE["dropout"] = BenchmarkGroup()
for rank in (2,), N in (10^2, 10^3, 10^4)
    size_suite = BenchmarkGroup()
    SUITE["dropout"]["$(rank+2)-N($N)"] = size_suite

    x = ones(Float32, repeat([N], rank)..., 1, 1)
    y = zeros(Float32, repeat([N], rank)..., 1, 1)
    p = 0.2

    dropout_suite = BenchmarkGroup()
    dropout_suite["with-colon"] = @benchmarkable dropout($x, $p)
    dropout_suite["with-dim"] = @benchmarkable dropout($x, $p; dims = 1)
    SUITE["dropout"]["$(rank+2)-N($N)"]["dropout"] = dropout_suite

    dropout!_suite = BenchmarkGroup()
    dropout!_suite["with-colon"] = @benchmarkable dropout!($y, $x, $p)
    dropout!_suite["with-dim"] = @benchmarkable dropout!($y, $x, $p; dims = 1)
    SUITE["dropout"]["$(rank+2)-N($N)"]["dropout!"] = dropout!_suite
end


########## upsample ############
SUITE["upsample"] = BenchmarkGroup()
SUITE["upsample"]["linear"] = BenchmarkGroup()
for rank in (2,), et in (Float16, Float32)
    et_suite = BenchmarkGroup("fw" => BenchmarkGroup(), "bw" => BenchmarkGroup())
    SUITE["upsample"]["linear"][string(et)] = et_suite

    inputs_sizes = [
        (128, 2, true), (128, (1, 2), false), (256, 4, true),
        (256, 8, false), (1024, (0.5, 2), false),
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

SUITE["upsample"]["nearest"] = BenchmarkGroup()
for rank in (2,), N in (128, 512, 2048,)
    et_suite = BenchmarkGroup()
    for et in (Float16, Float32, Float64)
        x = zeros(Float32, repeat([N], rank)..., 1, 1)
        et_suite[string(et)] = @benchmarkable upsample_nearest($x; size = (repeat([$N * 10], $rank)..., 1, 1))
    end
    SUITE["upsample"]["nearest"]["$(rank+2)-N($N)"] = et_suite
end
