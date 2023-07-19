########## attention ############
SUITE["nnlib"]["attention"] = BenchmarkGroup()
for et in (Float16, Float64)
    et_suite = BenchmarkGroup(
        "attention" => BenchmarkGroup(), "score" => BenchmarkGroup())
    SUITE["nnlib"]["attention"][string(et)] = et_suite

    input_items = [
        ((16,128,8), (16,512,8), (32,512,8), (512,128), 4),
        ((64,64,16), (64,64,16), (64,64,16), (64,64), 4),
        ((8,6,1), (8,10,1), (4,10,1), nothing, 1),
    ]
    for (q_sz, k_sz, v_sz, bias_sz, nheads) in input_items
        q, q_score = rand(et, q_sz...), rand(et, 8, q_sz...)
        k, k_score = rand(et, k_sz...), rand(et, 8, k_sz...)
        v = rand(et, v_sz...)
        bias = isnothing(bias_sz) ? nothing : rand(et, bias_sz...)
        mask = isnothing(bias_sz) ? nothing : rand(Bool, bias_sz...)
        et_suite["attention"][
            "q($q_sz)-k($k_sz)-v($v_sz)-bias($bias_sz)-nheads($nheads)"
        ] = @benchmarkable dot_product_attention($q, $k, $v, $bias; nheads = $nheads)
        et_suite["score"][
            "q(8, $q_sz)-k(8, $k_sz)-bias($bias_sz)-nheads($nheads)"
        ] = @benchmarkable dot_product_attention_scores($q_score, $k_score, $bias; mask = $mask)
    end
end
