using BenchmarkCI: printresultmd, CIResult
using PkgBenchmark
using Markdown

const BENCHMARK_RESULT_PREFIX = "fluxml-benchmark-result-"
const BASELINE_RESULT_FILE_NAME = "result-baseline.json"
const TARGET_RESULT_FILE_NAME = "result-target.json"

"""
    get_result_files(base_path::String)::Tuple{Vector{String}, Vector{String}}

is used to get all the JSON output generated by PkgBenchmark.benchmarkpkg.

To accelerate benchmarking and avoid OOM, this tool splits the whole process
into several small tasks. Each of those task generates its own output.

After benchmarking, result-baseline.json and result-target.json are both in
"benchmark/". The workflow uses "upload-artifact" action to upload these JSON
files, while latter jobs use "download-artifact" action to download them. (
all artifacts are included a directory prefixed with "fluxml-benchmark-result-")

In MergeReport job, it will download all the results. And this function aims
to find all the "result-baseline.json" and "result-target.json".

* base_path: to specify the path artifacts located, "." by default
"""
function get_result_files(base_path::String = ".")::Tuple{Vector{String}, Vector{String}}
    baseline_results = []
    target_results = []
    all_benchmark_result_dirs = [
        f for f in readdir(base_path) if isdir(f) &&
        startswith(f, BENCHMARK_RESULT_PREFIX)
    ]
    for dir in all_benchmark_result_dirs
        result_dir_contents = readdir(dir)
        BASELINE_RESULT_FILE_NAME in result_dir_contents ||
            error("$BASELINE_RESULT_FILE_NAME is not in $dir")
        TARGET_RESULT_FILE_NAME in result_dir_contents ||
            error("$TARGET_RESULT_FILE_NAME is not in $dir")
        push!(baseline_results, "$dir/$BASELINE_RESULT_FILE_NAME")
        push!(target_results, "$dir/$TARGET_RESULT_FILE_NAME")
    end
    return (baseline_results, target_results)
end


"""
    merge_results(a::BenchmarkResults, b::BenchmarkResults)::BenchmarkResults

is used to merge two different BenchmarkResults.

Here only assign all the k-v pairs of param `b` to param `a`.
"""
function merge_results(a::BenchmarkResults, b::BenchmarkResults)::BenchmarkResults
    out = deepcopy(a)
    for (key, bg) in b.benchmarkgroup
        out.benchmarkgroup[key] = bg
    end
    return out
end

function merge_results(input::Vector{BenchmarkResults})
    # That varargs is the only parameter may be a bit strange in Julia
    isempty(input) && error("When trying to merge BenchmarkResults, receive 0 results")
    return reduce(merge_results, input)
end

function merge_results(file_a::String, file_b::String)::BenchmarkResults
    isfile(file_a) || error("the benchmark result json ($(file_a)) doesn't exist")
    isfile(file_b) || error("the benchmark result json ($(file_b)) doesn't exist")
    a = readresults(file_a)
    b = readresults(file_b)
    return merge_results(a, b)
end

function merge_results(a::BenchmarkResults, file_b::String)::BenchmarkResults
    isfile(file_b) || error("the benchmark result json ($(file_b)) doesn't exist")
    b = readresults(file_b)
    return merge_results(a, b)
end

function merge_results(input_result_files::Vector{String})::BenchmarkResults
    isempty(input_result_files) && error("When trying to merge BenchmarkResults, receive 0 results")
    return reduce(merge_results, input_result_files)
end


"""
    markdown_report(judgement::BenchmarkJudgement)

Return markdown content (String) by the result of BenchmarkTools.judge.
"""
function markdown_report(judgement::BenchmarkJudgement)
    md = sprint(printresultmd, CIResult(judgement = judgement))
    md = replace(md, ":x:" => "❌")
    md = replace(md, ":white_check_mark:" => "✅")
    return md
end


"""
    display_markdown_report(report_md)

Display the content of the report after parsed by Markdown.parse.

* report_md: the result of [`markdown_report`](@ref)
"""
display_markdown_report(report_md) = display(Markdown.parse(report_md))
