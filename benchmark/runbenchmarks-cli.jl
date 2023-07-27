using Pkg
Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

parsed_args = parse_commandline()
retune_arg = parsed_args["retune"]
retune_arg || get_tuning_json()
enable_arg, disable_arg = parsed_args["enable"], parsed_args["disable"]
enabled_benchmarks = parse_enabled_benchmarks(enable_arg, disable_arg)

deps_list = parsed_args["deps-list"]
parsed_deps_list = parse_deps_list(deps_list)
for (i, deps) in enumerate(parsed_deps_list)
    time_setup_fluxml_env = @elapsed setup_fluxml_env(deps)
    @info "($i) TIME: setup FluxML benchmarking environment cost $time_setup_fluxml_env"
    
    using PkgBenchmark: benchmarkpkg, BenchmarkConfig
    time_run_benchmarks = @elapsed begin benchmarkpkg(
        dirname(@__DIR__),
        BenchmarkConfig(
            env = merge(
                Dict("JULIA_NUM_THREADS" => get(ENV, "JULIA_NUM_THREADS", "1")),
                enabled_benchmarks
            )
        ),
        resultfile = joinpath(@__DIR__, "result-$i.json")
    ) end
    @info "($i) TIME: run benchmarks cost $time_run_benchmarks"

    teardown()
end
