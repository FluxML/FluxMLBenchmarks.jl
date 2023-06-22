using Pkg

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks
parsed_args = parse_commandline()

baseline_url = parsed_args["baseline"]
setup_fluxml_env(Vector([baseline_url]))

using PkgBenchmark
mkconfig(; kwargs...) = BenchmarkConfig(
    env = Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1"));
    kwargs...
)

group_baseline = benchmarkpkg(
    dirname(@__DIR__),
    mkconfig(id = baseline),
    resultfile = joinpath(@__DIR__, "result-$(baseline).json")
)

teardown()

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

target = parsed_args["target"]
setup_fluxml_env()

using PkgBenchmark
group_target = benchmarkpkg(
    dirname(@__DIR__),
    mkconfig(id = target),
    resultfile = joinpath(@__DIR__, "result-$(target).json"),
)

teardown()

###########################################################################

judgement = judge(group_target, group_baseline)
report_md = markdown_report(judgement)
write(joinpath(@__DIR__, "report.md"), report_md)
display_markdown_report(report_md)
