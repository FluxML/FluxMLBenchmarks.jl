using ArgParse
using OrderedCollections
using Pkg
using URIParser

"""
BENCHMARK_PKG_PATH means the relative path of benchmark folder,
which should be changed if the benchmark code is moved elsewhere.
"""
const BENCHMARK_PKG_PATH = "./benchmark"

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
FLUXML_PKGS mean the packages in FluxML community,
which are used directly or indirectly by Flux.jl.
"""
const FLUXML_PKGS = [
    "MacroTools", "IRTools", "ZygoteRules", "Functors", "NNlib",
    "Optimisers", "Zygote", "OneHotArrays", "Flux"
]

"""
BENCHMARK_FILES_PATH means the folder containing benchmark files.
FLUXML_AVAILABLE_TOP_LEVEL_BENCHMARKS is a vector, each element of it means
an available benchmark file under BENCHMARK_FILES_PATH.
"""
const BENCHMARK_FILES_PATH = "$(BENCHMARK_PKG_PATH)/benchmark"
const FLUXML_AVAILABLE_TOP_LEVEL_BENCHMARKS = [
    "flux", "nnlib"
]

"""
SUPPORTED_ARCHITECTURES means the supported architecture for this tool.
"""
const SUPPORTED_ARCHITECTURES = [
    "cpu", "gpu"
]


"""
    Dependency

is used as an abstract layer between PackageSpec and user input.
Eliminate unnecessary fields of PackageSpec and provide more functionalities.

* name: the name of dependency, the same as PackageSpec.name.
* url: the url of dependency, the same as PackageSpec.url.
* rev: the commit id of dependency, the same as PackageSpec.rev.
* version: the version of dependency, the same as Packagespec.version.
"""
struct Dependency
    name::Union{Nothing, String}
    url::Union{Nothing, String}
    rev::Union{Nothing, String}
    version::Union{Nothing, String}
end

function Dependency(;name::Union{Nothing,String} = nothing,
                    url::Union{Nothing,String} = nothing,
                    rev::Union{Nothing,String} = nothing,
                    version::Union{Nothing,String} = nothing)
    !isnothing(name) || !isnothing(url) || !isnothing(rev) ||
        isnothing(version) || throw(error("illegel input of Dependency"))
    Dependency(name, url, rev, version)
end

function Dependency(dep::String)
    if (m = match(r"https://github.com/(.*?)/(.*?)#(.*?)$", dep)) !== nothing
        Dependency(rev = string(m.captures[3]),
            url = "https://github.com/$(m.captures[1])/$(m.captures[2])")
    elseif (m = match(r"https://github.com/(.*?)/(.*?)@(.*?)$", dep)) !== nothing
        Dependency(version = string(m.captures[3]),
            url = "https://github.com/$(m.captures[1])/$(m.captures[2])")
    elseif (m = match(r"https://github.com/(.*?)/(.*?)", dep)) !== nothing
        Dependency(url = dep)
    elseif (m = match(r"(.*?)#(.*?)$", dep)) !== nothing
        Dependency(name = string(m.captures[1]),
                   rev = string(m.captures[2]))
    elseif (m = match(r"(.*?)@(.*?)$", dep)) !== nothing
        Dependency(name = string(m.captures[1]),
                   version = string(m.captures[2]))
    else
        Dependency(name = dep)
    end
end


"""
    get_name(dep::Dependency)

return the name of Dependency.
"""
function get_name(dep::Dependency)
    if !isnothing(dep.name)
        dep.name
    elseif !isnothing(dep.url)
        # TODO: unable to handle renamed fork repo
        # e.g. dep.url == https://github.com/skyleaworlder/NNlib.jl
        #      m.captures == ["skyleaworlder", "NNlib"]
        regex = r"https://github.com/(.*?)/(.*?).jl$"
        (m = match(regex, dep.url)) !== nothing || throw(
            "url ($(dep.url)) of Dependency not valid; need satisfy $(regex)")
        m.captures[2]
    else
        throw(error("Dependency ($(dep)) is not valid"))
    end
end


"""
    convert_to_packagespec

A convert function, used to convert Dependency to PackageSpec.
"""
function convert_to_packagespec(dep::Dependency)
    if !isnothing(dep.url)
        if !isnothing(dep.version)
            PackageSpec(url = dep.url, version = dep.version)
        elseif !isnothing(dep.rev)
            PackageSpec(url = dep.url, rev = dep.rev)
        else
            PackageSpec(url = dep.url)
        end
    elseif !isnothing(dep.name)
        if !isnothing(dep.version)
            PackageSpec(name = dep.name, version = dep.version)
        elseif !isnothing(dep.rev)
            PackageSpec(name = dep.name, rev = dep.rev)
        else
            PackageSpec(name = dep.name)
        end
    else throw(error(
        "illegel input: both name and url are nothing ($(dep))"))
    end
end


"""
    init_dependencies()::Dict{String, Pkg.Types.PackageSpec}

generate the latest version of PackageSpecs directly.
"""
init_dependencies() = OrderedDict((pkg, PackageSpec(pkg)) for pkg in FLUXML_PKGS)


"""
    init_dependencies(deps::Vector{Dependency})

generate dependencies with the given specification:

* in deps: create dependencies in specification.
* default: the latest version of dependencies
"""
function init_dependencies(deps::Vector{Dependency})
    init_deps = init_dependencies()
    for dep in deps
        pkg_name = get_name(dep)
        !haskey(init_deps, pkg_name) && throw(error(
            "default dependencies don't have the key ($(pkg_name))"))
        push!(init_deps, pkg_name => convert_to_packagespec(dep))
    end
    return init_deps
end


"""
    install_benchmark_basic_deps

is used to install dependencies in benchmark part rather than FluxMLBenchmarks
"""
function install_benchmark_basic_deps()
    @info "begin to install basic deps"
    for dep in BENCHMARK_BASIC_DEPS
        Pkg.add(dep)
    end
end


"""
    parse_commandline

is used to get command arguments.

About url passed to Pkg.add, see https://pkgdocs.julialang.org/v1/managing-packages/#Adding-unregistered-packages
"""
function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        # about script
        "--cli"
            help = "Go to execute benchmark/script/runbenchmarks-cli.jl.
                    You can specify --deps-list --enable --disable"
            action = :store_true
        "--pr"
            help = "Go to execute benchmark/script/runbenchmarks-pr.jl.
                    You can specify --target --baseline --enable --disable"
            action = :store_true
        "--merge-reports"
            help = "Go to execute benchmark/script/mergereports-cli.jl.
                    You can specify --target --baseline --push-result
                    --push-username --push-useremail --push-password"
            action = :store_true
        "--cache-setup"
            help = "Go to execute benchmark/script/cachesetup-cli.jl.
                    You can specify --target --baseline"
            action = :store_true

        # about benchmarks
        "--enable"
            help = "Specified benchmark sections to execute.
                    e.g. flux,nnlib,optimisers
                    By default, all benchmarks are enabled."
            action = :store_arg
            default = reduce((x,y) -> "$x,$y", FLUXML_AVAILABLE_TOP_LEVEL_BENCHMARKS)
        "--disable"
            help = "Specified benchmark sections not to execute,
                    e.g. nnlib,flux
                    no benchmarks are disabled by default."
            action = :store_arg
            default = ""
        "--target"
            help = "Repo URL to use as target. No default value.
                    e.g. https://github.com/FluxML/NNlib.jl#segfault"
            action = :store_arg
        "--baseline"
            help = "Repo URL to use as baseline. No default value.
                    e.g. https://github.com/FluxML/NNlib.jl#segfault"
            action = :store_arg
        "--deps-list"
            help = "This is a single string that simulates an array,
                    with each element separated by a semicolon.
                    Each element consists of two parts:
                    the first part is a dependent version,
                    and the second part is another dependent version.
                    e.g. 'dep1,dep1a;dep2,dep2a;dep3,dep3b'"
            action = :store_arg
        "--retune"
            help = "force re-tuning (ignore existing tuning data)"
            action = :store_true

        # about git
        "--fetch-result"
            help = "skip fetching result.json of baseline from remote"
            action = :store_true
        "--push-result"
            help = "skip pushing result.json of target to remote"
            action = :store_true
        "--push-username"
            help = "used to authenticate when pushing"
            action = :store_arg
        "--push-useremail"
            help = "used to authenticate when pushing"
            action = :store_arg
        "--push-password"
            help = "used to authenticate when pushing"
            action = :store_arg

        # about architecture
        "--arch"
            help = "enable gpu benchmarks"
            action = :store_arg
            default = "cpu"
    end
    args = parse_args(s)
    # script-related arguments cli / pr / merge-report / cache-setup
    # There cannot be more than 1 true specified concurrently.
    count([args["cli"], args["pr"], args["merge-reports"], args["cache-setup"]]) > 1 &&
        throw(error("There cannot be more than 1 true for script-related arguments"))

    # if push-result is true, push-password must be provided
    args["push-result"] && isnothing(args["push-password"]) &&
        throw(error("Must provide 'push-password' if you want to 'push-result'"))
    
    # if arch is in SUPPORTED_ARCHITECTURES, allow returning args
    !(args["arch"] in SUPPORTED_ARCHITECTURES) &&
        throw(error("--arch must be in SUPPORTED_ARCHITECTURES"))

    # if (deps-list) or (target & baseline) specified, allow returning args
    !isnothing(args["deps-list"]) && return args
    !isnothing(args["target"]) && !isnothing(args["baseline"]) &&
        return args
    
    # Any other cases are considered incorrect
    throw(error(
        "Must provide 'deps-list' or both 'target' and 'baseline' as command args"))
end


"""
    parse_deps(deps)::Vector{Dependency}

is used to parse dependencies.

* deps: suggested to be a string, can be `--target` or `--baseline`

e.g. deps can be like "NNlib,Flux" or
    "https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test,Flux#0.13.12"
"""
parse_deps(deps) = map(dep -> Dependency(string(dep)), split(deps, ","))


"""
    parse_deps_list(deps_list::String)::Union{Vector{Dependency}, Tuple}

is used to parse command argument, "deps-list" represents multiple sets of dependencies.
Each element separated by a semicolon. Each element consists of any number of deps.
Now, deps_list only supports FluxML packages.

e.g. deps_list can be
    "NNlib,Flux;https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test,Flux#0.13.12"

return type:
* if deps_list only includes single deps set, return `Vector{Dependency}`
* if deps_list includes multiple sets, return `Tuple{Vector{Dependency}}`
"""
function parse_deps_list(deps_list::String)::Union{Vector{Dependency}, Tuple}
    parsed_deps_list = [parse_deps(deps) for deps in split(deps_list, ";")]
    return if length(parsed_deps_list) == 1
        parsed_deps_list[1]
    else
        Tuple(parsed_deps_list)
    end
end


"""
    setup

is used to activate environment, change dir and install dependencies.
"""
function setup(deps::Vector{PackageSpec})
    @info "begin to setup benchmark environment"
    Pkg.activate(BENCHMARK_PKG_PATH)
    cd(BENCHMARK_PKG_PATH)
    @info "pwd is: $(pwd())"

    for dep in deps
        Pkg.add(dep)
    end
end


"""
    setup_fluxml_env

only pass the value of `init_dependencies()` (FLUXML_PKGS) to setup.
"""
function setup_fluxml_env()
    setup(collect(v for (k,v) in init_dependencies()))
    install_benchmark_basic_deps()
end

function setup_fluxml_env(deps::Vector{Dependency})
    setup(collect(v for (k,v) in init_dependencies(deps)))
    install_benchmark_basic_deps()
end

function setup_fluxml_env(dependency_urls::Vector{String})
    url_deps = map(url -> Dependency(url), dependency_urls)
    setup_fluxml_env(url_deps)
end


"""
    teardown

is used to remove all the package installed, change dir and reactivate base.
"""
function teardown()
    @info "teardown benchmark environment"
    Pkg.rm(all_pkgs = true)
    pwd = ENV["PWD"] # PWD in ENV means the original path where run the code
    @info "pwd: $pwd"
    cd(pwd)
end


"""
    parse_enabled_benchmarks(enable_cmd_arg::String, disable_cmd_arg::String)

is used to parses command-line arguments to determine the enabled benchmarks.
Return a Dict as a part of environment variables, which will be used in BenchmarkConfig.

* enable_cmd_arg: A string containing a comma-separated list of enabled benchmarks.
* disable_cmd_arg: A string containing a comma-separated list of disabled benchmarks.

If `enable_cmd_arg` is not included in FLUXML_AVAILABLE_TOP_LEVEL_BENCHMARKS, it will be reported
and ignored, which is similarly when `disable_cmd_arg` is not included in `enable_cmd_arg`.
"""
function parse_enabled_benchmarks(
                                    enable_cmd_arg::String,
                                    disable_cmd_arg::String
                                )::Dict{String, Bool}
    """
    segment :== <name> | <name>(<names>)
    <names> :== <name>,<names> | ϵ

    Now only able to process benchmark folder with two-levels.
    Return a tuple of two list, for top-level and second-level.
    """
    function handle_single_repo_benchmarks(segment)
        top_repo_benchmarks = []
        second_repo_benchmarks = []
        if isempty(segment)
            return top_repo_benchmarks, second_repo_benchmarks
        elseif (m = match(r"^(.*?)\((.+)\)$", segment)) !== nothing
            # e.g. top_level_bg: flux or nnlib
            # e.g. second_level_bgs: activations,gemm
            top_level_bg, second_level_bgs = m.captures[1], m.captures[2]
            if !isdir("$BENCHMARK_FILES_PATH/$top_level_bg")
                @warn "$top_level_bg is not a dir under $BENCHMARK_FILES_PATH"
                return top_repo_benchmarks, second_repo_benchmarks
            end
            push!(top_repo_benchmarks, top_level_bg)
            for second_bg in map(string, split(second_level_bgs, ","))
                push!(second_repo_benchmarks, "$(top_level_bg)_$(second_bg)")
            end
        else
            # e.g. top_level_bg: flux or nnlib
            top_level_bg = segment
            if !isdir("$BENCHMARK_FILES_PATH/$top_level_bg")
                @warn "$top_level_bg is not a dir under $BENCHMARK_FILES_PATH"
                return top_repo_benchmarks, second_repo_benchmarks
            end
            push!(top_repo_benchmarks, top_level_bg)
            for fn in readdir("$BENCHMARK_FILES_PATH/$top_level_bg")
                if (m = match(r"^(.*?).jl$", fn)) !== nothing
                    push!(second_repo_benchmarks, "$(top_level_bg)_$(m.captures[1])")
                end
            end
        end
        return top_repo_benchmarks, second_repo_benchmarks
    end

    cmd_enable = split(enable_cmd_arg, ";")
    cmd_disable = split(disable_cmd_arg, ";")

    enable_top_benchmarks = []
    enable_second_benchmarks = []
    for enabled in cmd_enable
        top_level_env, second_level_env = handle_single_repo_benchmarks(enabled)
        append!(enable_top_benchmarks, top_level_env)
        append!(enable_second_benchmarks, second_level_env)
    end

    disable_top_benchmarks = []
    disable_second_benchmarks = []
    for disabled in cmd_disable
        top_level_env, second_level_env = handle_single_repo_benchmarks(disabled)
        append!(disable_top_benchmarks, top_level_env)
        append!(disable_second_benchmarks, second_level_env)
    end

    remain_benchmark_files_name = setdiff(
        enable_second_benchmarks, disable_second_benchmarks)
    return Dict(
        "FLUXML_BENCHMARK_$(uppercase(fn))" => true
        for fn in vcat(enable_top_benchmarks, remain_benchmark_files_name)
    )
end
