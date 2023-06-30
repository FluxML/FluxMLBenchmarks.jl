<img align="right" width="200px" src="https://github.com/FluxML/OneHotArrays.jl/raw/main/docs/src/assets/logo.png">

# FluxMLBenchmarks

`FluxMLBenchmarks` is a benchmarking tool designed for FluxML community, which allows for the creation of different benchmarking environments by installing different sets of dependencies and comparing the results.

## Use cases

### 1. Command-Line Interface

#### i. Single Package

To observe whether there is a performance difference between two versions of **the same package**, `FluxMLBenchmarks` requires 2 arguments, `--baseline` and `--target`, to specify the 2 versions of **the same package**.

```shell
> BASELINE=<Dependency Representation of baseline>
> TARGET=<Dependency Representation of target>
> julia --project=benchmark benchmark/runbenchmarks-pr.jl --target=$TARGET --baseline=$BASELINE
```

For specification, `Dependency Representation` is similar to the `word` of [add - REPL command - Pkg.jl](https://pkgdocs.julialang.org/v1/repl/#package-commands), described as follows:

| format | example |
| :-: | :-: |
| `<pkg name>` | `Flux` |
| `<pkg name>@<version>` | `NNlib@0.8.20` |
| `<pkg name>#<branch name, commit id>` | `Zygote#master` or `Zygote#2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c` |
| `<url>` | `https://github.com/FluxML/Optimisers.jl` |
| `<url>@<version>` | `https://github.com/FluxML/OneHotArrays.jl@0.2.4` |
| `<url>#<branch name, commit id>` | `https://github.com/FluxML/Functors.jl#master` |

e.g.

```shell
> BASELINE="https://github.com/FluxML/NNlib.jl#backports-0.8.21"
> TARGET="https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test"
> julia --project=benchmark benchmark/runbenchmarks-pr.jl --target=$TARGET --baseline=$BASELINE
```

#### ii. Multiple Packages

The performance of a package need measured under the condition that other packages and tools remain constant. However, in the case of mutual influence between **multiple packages of different versions**, **2 sets of dependencies** need to be provided simultaneously. To meet this benchmarking requirements, you can use `--deps-list`:

```shell
> DEPS_LIST=<Dependencies List>
> julia --project=benchmark benchmark/runbenchmarks-cli.jl --deps-list=$DEPS_LIST
```

For specification, `Dependencies List` is a single string that simulates an array, with each element separated by a semicolon. Each element consists of two parts:

* the first part is a dependent version,
* the second part is another dependent version.

e.g.

```shell
> DEPS_LIST="https://github.com/FluxML/NNlib.jl#backports-0.8.21,https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test;Flux,Flux@0.13.12"
> julia --project=benchmark benchmark/runbenchmarks-cli.jl --deps-list=$DEPS_LIST
```

### 2. GitHub Pull Request

TODO
