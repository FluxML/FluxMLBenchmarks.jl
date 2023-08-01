using Pkg
Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks
FluxMLBenchmarks.install_benchmark_basic_deps()

# merge BenchmarkResults
using PkgBenchmark
baseline_results, target_results = get_result_files_from_artifacts(pwd())
baseline_benchmarkresults = merge_results(baseline_results)
target_benchmarkresults = merge_results(target_results)

# push report to git repository
parsed_args = parse_commandline()
if parsed_args["push-result"] && suitable_to_use_result_cache(parsed_args["target"])
    @info "RESULT: $target_url is suitable to push its result to remote"
    writeresults(joinpath(@__DIR__, "result-target.json"), target_benchmarkresults)
    push_result(target_url, joinpath(@__DIR__, "result-target.json")
              ; git_push_password = parsed_args["push-password"])
end

# generate report.md as the content of comment
judgement = judge(target_benchmarkresults, baseline_benchmarkresults)
report_md = markdown_report(judgement)
write(joinpath(@__DIR__, "report.md"), report_md)
display_markdown_report(report_md)
