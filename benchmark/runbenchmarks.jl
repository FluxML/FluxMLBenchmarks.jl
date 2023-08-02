using Pkg
Pkg.develop(PackageSpec(path = ENV["PWD"]))
using FluxMLBenchmarks

function entry()
    parsed_args = parse_commandline()
    parsed_args["cache-setup"] && include("script/cachesetup-cli.jl")
    parsed_args["merge-reports"] && include("script/mergereports-cli.jl")
    parsed_args["cli"] && include("script/runbenchmarks-cli.jl")
    parsed_args["pr"] && include("script/runbenchmarks-pr.jl")
end

entry()
