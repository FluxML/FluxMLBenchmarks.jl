using ArgParse
using Pkg
using URIParser

"""
BENCHMARK_PKG_PATH means the relative path of benchmark folder,
which should be changed if the benchmark code is moved elsewhere.
"""
const BENCHMARK_PKG_PATH = "../benchmark/"

"""
FLUXML_PKGS mean the packages in FluxML community,
which are used directly or indirectly by Flux.jl.
"""
const FLUXML_PKGS = Set((
    "Flux", "NNlib", "Zygote", "NNlibCUDA", "Optimizers", "OneHotArrays",
    "Functors", "ZygoteRules", "IRTools", "MacroTools"
))


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


"""
    get_name(dep::Dependency)

return the name of Dependency.
"""
function get_name(dep::Dependency)
    if !isnothing(dep.name)
        dep.name
    elseif !isnothing(dep.url)
        # TODO: maybe something wrong
        path_segments = split(URI(dep.url).path, "/")
        (length(path_segments) < 3) && throw(error(
            "Dependency URL ($(uri)) is not qualified"))
        path_segments[3]
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
    if !isnothing(dep.url) PackageSpec(url = dep.url)
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
BENCHMARK_UTIL_DEPS mean the dependencies required to be installed before
running benchmarks.
"""
const BENCHMARK_UTIL_DEPS = Vector{Dependency}([
    Dependency(name = "BenchmarkCI", version = "0.1"),
    Dependency(name = "BenchmarkTools", version = "1.3"),
    Dependency(name = "PkgBenchmark", version = "0.2")
])


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
    parse_commandline

used to get command arguments.
"""
function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--target"
            help = "the branch/commit/tag to use as target"
            default = "HEAD"
        "--baseline"
            help = "the branch/commit/tag to use as baseline"
            default = "main"
        "--retune"
            help = "force re-tuning (ignore existing tuning data)"
            action = :store_false
    end
    return parse_args(s)
end


function setup(deps::Vector{PackageSpec})
    Pkg.activate(BENCHMARK_PKG_PATH)
    cd(BENCHMARK_PKG_PATH)

    for dep in deps
        Pkg.add(dep)
    end
end


function teardown()
    Pkg.rm(all_pkgs = true)
    pwd = ENV["PWD"] # PWD in ENV means the original path where run the code
    Pkg.activate(pwd)
    cd(pwd)
end
