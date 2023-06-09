using Pkg

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

parsed_args = parse_commandline()
deps_list = parsed_args["deps-list"]
baseline_fluxml_deps, target_fluxml_deps = parse_deps_list(deps_list)
enable_arg = parsed_args["enable"]
disable_arg = parsed_args["disable"]
enabled_benchmarks = parse_enabled_benchmarks(enable_arg, disable_arg)

setup_fluxml_env(baseline_fluxml_deps)

using BenchmarkTools
BenchmarkTools.DEFAULT_PARAMETERS.samples = 20
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 2.5

using PkgBenchmark
group_baseline = benchmarkpkg(
    dirname(@__DIR__),
    BenchmarkConfig(
        env = merge(
            Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1")),
            enabled_benchmarks
        )
    ),
    resultfile = joinpath(@__DIR__, "result-baseline.json")
)

teardown()

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

setup_fluxml_env(target_fluxml_deps)

using BenchmarkTools
BenchmarkTools.DEFAULT_PARAMETERS.samples = 20
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 2.5

using PkgBenchmark
group_target = benchmarkpkg(
    dirname(@__DIR__),
    BenchmarkConfig(
        env = merge(
            Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1")),
            enabled_benchmarks
        )
    ),
    resultfile = joinpath(@__DIR__, "result-target.json"),
)

teardown()

###########################################################################

judgement = judge(group_target, group_baseline)
report_md = markdown_report(judgement)
write(joinpath(@__DIR__, "report.md"), report_md)
display_markdown_report(report_md)
