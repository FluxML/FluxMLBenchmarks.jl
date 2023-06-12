# Adapted from
# https://github.com/kul-forbes/ProximalOperators.jl/tree/master/benchmark
using PkgBenchmark
using FluxMLBenchmarks: markdown_report, display_markdown_report, parse_commandline

function main()
    parsed_args = parse_commandline()

    mkconfig(; kwargs...) =
        BenchmarkConfig(
            env = Dict(
                "JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1"),
            );
            kwargs...
        )

    baseline = parsed_args["baseline"]
    group_baseline = benchmarkpkg(
        dirname(@__DIR__),
        mkconfig(id = baseline),
        resultfile = joinpath(@__DIR__, "result-$(baseline).json"),
        retune = parsed_args["retune"],
    )

    target = parsed_args["target"]
    group_target = benchmarkpkg(
        dirname(@__DIR__),
        mkconfig(id = target),
        resultfile = joinpath(@__DIR__, "result-$(target).json"),
    )

    judgement = judge(group_target, group_baseline)
    report_md = markdown_report(judgement)
    write(joinpath(@__DIR__, "report.md"), report_md)
    display_markdown_report(report_md)
end

main()
