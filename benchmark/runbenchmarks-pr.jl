using Pkg

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

parsed_args = parse_commandline()

enable_arg = parsed_args["enable"]
disable_arg = parsed_args["disable"]
enabled_benchmarks = parse_enabled_benchmarks(enable_arg, disable_arg)

baseline_url = parsed_args["baseline"]
time_setup_fluxml_env = @elapsed setup_fluxml_env([baseline_url])
@info "TIME: setup FluxML benchmarking environment (baseline) cost $time_setup_fluxml_env"

using BenchmarkTools
using PkgBenchmark
time_run_benchmarks = @elapsed begin group_baseline = benchmarkpkg(
    dirname(@__DIR__),
    BenchmarkConfig(
        env = merge(
            Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1")),
            enabled_benchmarks
        )
    ),
    resultfile = joinpath(@__DIR__, "result-baseline.json")
) end
@info "TIME: run benchmarks (baseline) cost $time_run_benchmarks"

teardown()

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

target_url = parsed_args["target"]
time_setup_fluxml_env = @elapsed setup_fluxml_env([target_url])
@info "TIME: setup FluxML benchmarking environment (target) cost $time_setup_fluxml_env"

using BenchmarkTools
using PkgBenchmark
time_run_benchmarks = @elapsed begin group_target = benchmarkpkg(
    dirname(@__DIR__),
    BenchmarkConfig(
        env = merge(
            Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1")),
            enabled_benchmarks
        )
    ),
    resultfile = joinpath(@__DIR__, "result-target.json"),
) end
@info "TIME: run benchmarks (target) cost $time_run_benchmarks"

teardown()

###########################################################################

judgement = judge(group_target, group_baseline)
report_md = markdown_report(judgement)
write(joinpath(@__DIR__, "report.md"), report_md)
display_markdown_report(report_md)
