using Pkg
Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

parsed_args = parse_commandline()

if (deps_list = parsed_args["deps-list"]) !== nothing
    baseline_fluxml_deps, target_fluxml_deps = parse_deps_list(deps_list)
elseif parsed_args["baseline"] !== nothing && parsed_args["target"] !== nothing
    baseline_fluxml_deps = [parsed_args["baseline"]]
    target_fluxml_deps = [parsed_args["target"]]
else
    @error "Must provide 'deps-list' or 'baseline & target'"
end

time_setup_fluxml_env = @elapsed setup_fluxml_env([
    baseline_fluxml_deps; target_fluxml_deps
])
@info "TIME: setup FluxML benchmarking environment cost $time_setup_fluxml_env"
