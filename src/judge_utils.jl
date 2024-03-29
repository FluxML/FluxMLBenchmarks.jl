using BenchmarkCI: printresultmd, CIResult
using BenchmarkTools
using PkgBenchmark
using Markdown
using SHA
using LibGit2

const RESULTS_BRANCH = "benchmark-results"
const BASELINE_RESULT_FILENAME = "benchmark/result-baseline.json"
const TARGET_RESULT_FILENAME = "benchmark/result-target.json"

const BENCHMARK_RESULT_PREFIX = "fluxml-benchmark-result-"
const BASELINE_RESULT_FILE_NAME = "result-baseline.json"
const TARGET_RESULT_FILE_NAME = "result-target.json"


"""
    gen_result_filename(single_deps_list::String; arch = "cpu")::String

is used to generate the filename of benchmark results.
The name of results doesn't have relationship with BenchmarkResults,
but highly relevant to dependencies. With the help of this function,
we can use the information of dependencies to specify a file.

* single_deps_list: a part of command argument, `deps-list`.
                    `target` and `baseline` also can passed in.
"""
function gen_result_filename(single_deps_list::String; arch = "cpu")::String
    # keep deps in sort, in case impact of different sequence.
    sorted_deps = reduce((a, b) -> "$a,$b",
        sort(map(string, split(single_deps_list, ","))))
    return "$(arch)-$(bytes2hex(sha256(sorted_deps))).json"
end


"""
    suitable_to_use_result_cache(single_deps_list::String)

is used to judge if this deps list can use results cache. It cannnot use cache
in the following cases:

1. exists a dependency without version or revision
2. exists a dependency with revision but it's a branch name
"""
function suitable_to_use_result_cache(single_deps_list::String)
    deps = map(dep -> Dependency(dep), map(string, split(single_deps_list, ",")))
    for dep in deps
        # without version or revision
        isnothing(dep.version) &&
        isnothing(dep.rev) &&
            return false

        # require: length(commit_id) >= 6
        if !isnothing(dep.rev)
            m = match(r"^[0-9a-fA-F]{6,}$", dep.rev)
            isnothing(m) && return false
        end
    end
    return true
end


"""
    get_result_file_from_branch(single_deps_list::String; arch = "cpu")

is used to checkout corresponding result file from benchmark-results branch.
If possible, the result will help to skip benchmarks running.

* single_deps_list: target / baseline command argument
* checkout_filename: whose name is a filename, and the content of this file is
the content of a file checked out by git. It can be "benchmark/result-baseline.json"

TODO: badly-designed in semantic, due to the usage of `gen_result_filename``
"""
function get_result_file_from_branch(single_deps_list::String, checkout_filename::String; arch = "cpu")
    result_filename = gen_result_filename(single_deps_list; arch=arch)
    cmd = pipeline(`git show $RESULTS_BRANCH:$result_filename`
                    ; stdout=checkout_filename)
    try
        @info "try to checkout result file ($result_filename) in branch $RESULTS_BRANCH."
        run(cmd)
        return
    catch
        @warn "$RESULTS_BRANCH:$result_filename not existed"
        isfile(checkout_filename) && rm(checkout_filename)
        rethrow()
    end
end


"""
    get_benchmarkresults_from_branch(single_deps_list::String; arch = "cpu")::Union{Nothing,BenchmarkResults}

is used to get BenchmarkResults from deps-list.
"""
function get_benchmarkresults_from_branch(single_deps_list::String; arch = "cpu")::Union{Nothing,BenchmarkResults}
    try
        get_result_file_from_branch(single_deps_list, "tmp.json"; arch=arch)
    catch
        @warn "RESULT: get_result_file_from_branch failed to get result file with $single_deps_list."
        return
    end
    return PkgBenchmark.readresults("tmp.json")
end


"""
    push_result(result_file_path::String)

is used to push the result file to remote branch.

* result_file_path: the file path of result file.

TODO: badly-designed in semantic, due to the usage of `gen_result_filename`
TODO: need better way to process git_push_username and git_push_password
"""
function push_result(single_deps_list::String, result_file_path::String
                    ; need_password = true, arch = "cpu", kwargs...)
    # FIXME: a little bit hacked
    REPO = LibGit2.GitRepo(joinpath(@__DIR__, "..", ".git"))
    origin_remote = LibGit2.lookup_remote(REPO, "origin")
    if isnothing(origin_remote)
        @warn "remote 'origin' is not existed in .git"
        return
    end

    origin_remote_url = LibGit2.url(origin_remote)
    br_repo = try
        LibGit2.clone(origin_remote_url, "../benchmark-result"; branch = RESULTS_BRANCH)
    catch e
        @warn "ERROR: $e"
        @warn "couldn't clone repo $origin_remote_url (branch: $RESULTS_BRANCH)"
        isdirpath("../benchmark-result") && rm("../benchmark-result")
        return
    end

    result_file_path_in_br_repo = joinpath(
        LibGit2.path(br_repo), gen_result_filename(single_deps_list; arch=arch))
    mv(result_file_path, result_file_path_in_br_repo)
    br_origin_remote = LibGit2.lookup_remote(br_repo, "origin")
    if isnothing(br_origin_remote)
        @warn "remote 'origin' is not existed in .git (branch: $RESULTS_BRANCH)"
        return
    end

    # prepare user signature for pushing results
    username = haskey(kwargs, :git_push_username) ?
            kwargs[:git_push_username] :
            "github-actions[bot]"
    email = haskey(kwargs, :git_push_email) ?
            kwargs[:git_push_email] :
            "github-actions[bot]@users.noreply.github.com"
    run(`git config --global user.name $username`)
    run(`git config --global user.email $email`)
    run(`git -C $(LibGit2.path(br_repo)) add $result_file_path_in_br_repo`)
    run(`git -C $(LibGit2.path(br_repo)) commit -m "Upload results of $single_deps_list"`)

    if need_password
        password = haskey(kwargs, :git_push_password) ?
            kwargs[:git_push_password] :
            throw(error("doesn't provide password but now you are pushing"))
        run(`git -C $(LibGit2.path(br_repo)) push https://$username:$password@github.com/FluxML/FluxMLBenchmarks.jl`)
    else
        run(`git -C $(LibGit2.path(br_repo)) push`)
    end
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


"""
    get_result_files_from_artifacts(base_path::String)::Tuple{Vector{String}, Vector{String}}

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
function get_result_files_from_artifacts(base_path::String)::Tuple{Vector{String}, Vector{String}}
    baseline_results = []
    target_results = []
    @info readdir(base_path)
    all_benchmark_result_dirs = [
        f for f in readdir(base_path) if isdir(f) &&
        startswith(f, BENCHMARK_RESULT_PREFIX)
    ]
    @info all_benchmark_result_dirs
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
    merge_benchmarkgroup(a::BenchmarkGroup, b::BenchmarkGroup)::BenchmarkGroup

is used to merge two different BenchmarkGroup.
"""
function merge_benchmarkgroup(a::BenchmarkGroup, b::BenchmarkGroup)::BenchmarkGroup
    out = deepcopy(a)
    for (key, bg) in b
        out[key] = haskey(a, key) ?
            merge_benchmarkgroup(a[key], bg) : bg
    end
    return out
end


"""
    merge_results(a::BenchmarkResults, b::BenchmarkResults)::BenchmarkResults

is used to merge two different BenchmarkResults.
"""
function merge_results(a::BenchmarkResults, b::BenchmarkResults)::BenchmarkResults
    return BenchmarkResults(
        a.name,
        a.commit,
        merge_benchmarkgroup(a.benchmarkgroup, b.benchmarkgroup),
        a.date,
        a.julia_commit,
        a.vinfo,
        a.benchmarkconfig
    )
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
    length(input_result_files) == 1 && return readresults(input_result_files[1])
    return reduce(merge_results, input_result_files)
end
