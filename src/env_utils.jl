using ArgParse
using Pkg
using URIParser

"""
BENCHMARK_PKG_PATH means the relative path of benchmark folder,
which should be changed if the benchmark code is moved elsewhere.
"""
const BENCHMARK_PKG_PATH = "./benchmark/"

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
    "Flux", "NNlib", "Zygote", "NNlibCUDA", "Optimisers", "OneHotArrays",
    "Functors", "ZygoteRules", "IRTools", "MacroTools"
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
        # e.g. dep.url == https://github.com/skyleaworlder/NNlib.jl#lppool
        #      path_segments == ["", "skyleaworlder", "NNlib.jl"]
        #      strip(path_segments[3], ['.', 'j', 'l']) == "NNlib"
        path_segments = split(URI(dep.url).path, "/")
        (length(path_segments) < 3) && throw(error(
            "Dependency URL ($(uri)) is not qualified"))
        # e.g. dep.url == https://github.com/FluxML/NNlib.jl@v0.8.21
        #      repo_name_segments == ["NNlib.jl", "v0.8.21"]
        repo_name_segments = split(path_segments[3], "@")
        strip(repo_name_segments[1], ['.', 'j', 'l'])
    else
        throw(error("Dependency is not qualified"))
    end
end


"""
    convert_to_packagespec

A convert function, used to convert Dependency to PackageSpec.
Currently, only support the following convertion:

* url provided: PackageSpec(url = url)
* name and rev provided: PackageSpec(name = name, rev = rev)
* name and version provided: PackageSpec(name = name, version = version)
"""
function convert_to_packagespec(dep::Dependency)
    if !isnothing(dep.url)
        # TODO: maybe only work in some cases
        # see JuliaLang/Pkg.jl src/REPLMode/argument_parser.jl PackageToken
        # and https://pkgdocs.julialang.org/v1/managing-packages/#Adding-unregistered-packages
        #
        # length(url_rev) < 2 => https://github.com/FluxML/NNlib.jl
        # length(url_rev) == 2 => https://github.com/skyleaworlder/NNlib.jl#lppool
        # rev can be a branch name or commit-SHA1-id
        url_rev = split(dep.url, "#")
        url_version = split(dep.url, "@")
        println(url_rev, url_version)
        if length(url_rev) == 2
            PackageSpec(url = url_rev[1], rev = url_rev[2])
        elseif length(url_version) == 2
            PackageSpec(
                url = url_version[1],
                version = string(url_version[2]))
        else
            PackageSpec(url = url_version[1])
        end
    elseif !isnothing(dep.name)
        if !isnothing(dep.rev) PackageSpec(name = dep.name, rev = dep.rev)
        elseif !isnothing(dep.version) PackageSpec(name = dep.name, version = dep.version)
        else throw(error(
            "illegel input: name is not nothing, but rev and version are nothing"))
        end
    else throw(error(
        "illegel input: both name and url are nothing"))
    end
end


"""
    init_dependencies()::Dict{String, Pkg.Types.PackageSpec}

generate the latest version of PackageSpecs directly.
"""
init_dependencies() = Dict((pkg, PackageSpec(pkg)) for pkg in FLUXML_PKGS)


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
        init_deps[pkg_name] = convert_to_packagespec(dep)
    end
    return init_deps
end


"""
    install_benchmark_basic_deps

is used to install dependencies in benchmark part rather than FluxMLBenchmarks
"""
function install_benchmark_basic_deps()
    println("begin to install basic deps")
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
            action = :store_false
    end
    args = parse_args(s)
    !isnothing(args["deps-list"]) && return args
    !isnothing(args["target"]) && !isnothing(args["baseline"]) &&
        return args
    throw(error(
        "Must provide 'deps-list' or both 'target' and 'baseline' as command args"))
end


"""
    parse_deps_list(deps_list::String)::Tuple{Vector{Dependency}, Vector{Dependency}}

is used to parse command argument, "deps-list", to 2 sets of dependencies,
which means parse_deps_list can support difference of multiple dependencies.
Each element separated by a semicolon. Each element consists of two parts:
the first part is baseline dependency, and the second part is target.
Now, deps_list only supports FluxML packages.

e.g. deps_list can be
    "NNlib,https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test;Flux,Flux#0.13.12"
"""
function parse_deps_list(deps_list::String)::Tuple{Vector{Dependency}, Vector{Dependency}}
    dep_pairs = filter(
        dep_pair_vec -> length(dep_pair_vec) == 2,
        map(
            dep_pair -> split(dep_pair, ","),
            split(deps_list, ";")))
    baseline_deps = map(
        baseline_dep -> Dependency(string(baseline_dep)),
        map(x -> x[1], dep_pairs))
    target_deps = map(
        target_dep -> Dependency(string(target_dep)),
        map(x -> x[2], dep_pairs))
    return (baseline_deps, target_deps)
end


"""
    setup

is used to activate environment, change dir and install dependencies.
"""
function setup(deps::Vector{PackageSpec})
    println("begin to setup benchmark environment")
    Pkg.activate(BENCHMARK_PKG_PATH)
    cd(BENCHMARK_PKG_PATH)
    println("pwd is: $(pwd())")

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


function setup_fluxml_env(dependency_urls::Vector{String})
    url_deps = map(url -> Dependency(url = url), dependency_urls)
    setup(collect(v for (k,v) in init_dependencies(url_deps)))
    install_benchmark_basic_deps()
end


"""
    teardown

is used to remove all the package installed, change dir and reactivate base.
"""
function teardown()
    println("teardown benchmark environment")
    Pkg.rm(all_pkgs = true)
    pwd = ENV["PWD"] # PWD in ENV means the original path where run the code
    println("pwd: $pwd")
    cd(pwd)
end
