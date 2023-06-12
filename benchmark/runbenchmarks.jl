using Pkg


"""
BENCHMARK_BASIC_DEPS mean the dependencies required to be installed before
running benchmarks.
"""
const BENCHMARK_BASIC_DEPS = [
    PackageSpec(name = "BenchmarkCI", version = "0.1"),
    PackageSpec(name = "BenchmarkTools", version = "1.3"),
    PackageSpec(name = "PkgBenchmark", version = "0.2")
]


"""
    install_basic_deps

is used to install dependencies in benchmark part rather than FluxMLBenchmarks
"""
function install_basic_deps()
    for dep in BENCHMARK_BASIC_DEPS
        Pkg.add(dep)
    end
end


install_basic_deps()
using PkgBenchmark
using FluxMLBenchmarks: markdown_report, display_markdown_report,
    parse_commandline, setup_fluxml_env, teardown

mkconfig(; kwargs...) = BenchmarkConfig(
    env = Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1"));
    kwargs...
)

parsed_args = parse_commandline()
baseline = parsed_args["baseline"]
setup_fluxml_env()

group_baseline = benchmarkpkg(
    dirname(@__DIR__),
    mkconfig(id = baseline),
    resultfile = joinpath(@__DIR__, "result-$(baseline).json"),
    retune = parsed_args["retune"],
)

teardown()

###########################################################################

install_basic_deps()
using PkgBenchmark
using FluxMLBenchmarks: markdown_report, display_markdown_report,
    parse_commandline, setup_fluxml_env, teardown

target = parsed_args["target"]
setup_fluxml_env()

group_target = benchmarkpkg(
    dirname(@__DIR__),
    mkconfig(id = target),
    resultfile = joinpath(@__DIR__, "result-$(target).json"),
)

teardown()

judgement = judge(group_target, group_baseline)
report_md = markdown_report(judgement)
write(joinpath(@__DIR__, "report.md"), report_md)
display_markdown_report(report_md)
