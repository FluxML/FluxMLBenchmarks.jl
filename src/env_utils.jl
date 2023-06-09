using Pkg

const BENCHMARK_PKG_PATH = "../benchmark/"

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
