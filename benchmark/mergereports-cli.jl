using Pkg
Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks
FluxMLBenchmarks.install_benchmark_basic_deps()

using PkgBenchmark
baseline_results, target_results = get_result_files(pwd())
baseline_benchmarkresults = merge_results(baseline_results)
target_benchmarkresults = merge_results(target_results)

judgement = judge(target_benchmarkresults, baseline_benchmarkresults)
report_md = markdown_report(judgement)
write(joinpath(@__DIR__, "report.md"), report_md)
display_markdown_report(report_md)
