module FluxMLBenchmarks

# Write your package code here.
include("env_utils.jl")
export Dependency, get_name, init_dependencies,
    parse_commandline, parse_deps_list,
    parse_enabled_benchmarks,
    setup_fluxml_env, teardown,
    BENCHMARK_PKG_PATH, BENCHMARK_FILES_PATH, FLUXML_AVAILABLE_BENCHMARKS

include("judge_utils.jl")
export markdown_report, display_markdown_report

end
