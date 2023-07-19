########## gemm ############
SUITE["nnlib"]["gemm"] = BenchmarkGroup()
for et in (Float32, Float64)
    et_suite = BenchmarkGroup(
        "gemm!" => BenchmarkGroup(),
        "batched_gemm!" => BenchmarkGroup())
    SUITE["nnlib"]["gemm"][string(et)] = et_suite

    # transA and transB are not of the main varaints.
    # gemm! meets some memory problem, not included here.
    input_items = [
        (Val(false), Val(false), 'N', 'N', 1024, 1024, 1024, et(0.5), et(0.0)),
        (Val(false), Val(false), 'N', 'N', 512, 512, 128, et(0.5), et(1.0)),
        (Val(false), Val(false), 'N', 'N', 80, 40, 100, et(1.0), et(0.0)),
    ]
    for (transA, transB, transA_ch, transB_ch, M, N, K, alpha, beta) in input_items
        bA = ones(et, M, N, 1)
        bB = ones(et, N, K, 1)
        bC = zeros(et, M, K, 1)
        et_suite["batched_gemm!"][
           "trans($transA_ch,$transB_ch)-M($M)-N($N)-K($K)-alpha($alpha)-beta($beta)"
        ] = @benchmarkable NNlib.batched_gemm!(
           $transA_ch, $transB_ch,
           $alpha, $bA, $bB, $beta, $bC)
    end
end
