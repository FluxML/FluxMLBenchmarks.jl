using Pkg

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

parsed_args = parse_commandline()
parsed_args["retune"] || get_tuning_json()
enable_arg, disable_arg = parsed_args["enable"], parsed_args["disable"]
enabled_benchmarks = parse_enabled_benchmarks(enable_arg, disable_arg)

baseline_url = parsed_args["baseline"]
baseline_deps = parse_deps_list(baseline_url)
group_baseline = nothing # just define group_baseline
try
    if !parsed_args["fetch-result"]
        @info "RESULT: skip fetching result.json from remote"
        throw("")
    end

    if !suitable_to_use_result_cache(baseline_url)
        @info "RESULT: not suitable_to_use_result_cache, run benchmarks"
        throw("")
    end

    global group_baseline = get_benchmarkresults_from_branch(baseline_url; arch=parsed_args["arch"])
    if isnothing(group_baseline)
        @warn "RESULT: cannot get result file, run benchmarks"
        throw("")
    end
catch
    time_setup_fluxml_env = @elapsed setup_fluxml_env(baseline_deps)
    @info "TIME: setup FluxML benchmarking environment (baseline) cost $time_setup_fluxml_env"

    using BenchmarkTools
    using PkgBenchmark
    time_run_benchmarks = @elapsed begin global group_baseline = benchmarkpkg(
        dirname(joinpath(@__DIR__, "../")),
        BenchmarkConfig(
            env = merge(
                Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1")),
                enabled_benchmarks
            )
        );
        script=joinpath(@__DIR__, "..", "benchmarks.jl"),
        resultfile = joinpath(@__DIR__, "..", "result-baseline.json")
    ) end
    @info "TIME: run benchmarks (baseline) cost $time_run_benchmarks"

    teardown()
end

###########################################################################

Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

target_url = parsed_args["target"]
target_deps = parse_deps_list(target_url)
time_setup_fluxml_env = @elapsed setup_fluxml_env(target_deps)
@info "TIME: setup FluxML benchmarking environment (target) cost $time_setup_fluxml_env"

using BenchmarkTools
using PkgBenchmark
time_run_benchmarks = @elapsed begin group_target = benchmarkpkg(
    dirname(joinpath(@__DIR__, "../")),
    BenchmarkConfig(
        env = merge(
            Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1")),
            enabled_benchmarks
        )
    );
    script=joinpath(@__DIR__, "..", "benchmarks.jl"),
    resultfile = joinpath(@__DIR__, "..", "result-target.json"),
) end
@info "TIME: run benchmarks (target) cost $time_run_benchmarks"

teardown()

###########################################################################

judgement = judge(group_target, group_baseline)
report_md = markdown_report(judgement)
write(joinpath(@__DIR__, "..", "report.md"), report_md)
display_markdown_report(report_md)
