<img align="right" width="200px" src="https://github.com/FluxML/OneHotArrays.jl/raw/main/docs/src/assets/logo.png">

# FluxMLBenchmarks

`FluxMLBenchmarks` is a benchmarking tool designed for FluxML community, which allows for the creation of different benchmarking environments by installing different sets of dependencies and comparing the results.

## Use cases

### 1. Command-Line Interface

#### i. Single Package

To observe whether there is a performance difference between two versions of **the same package**, `FluxMLBenchmarks` provides 2 arguments, `--baseline` and `--target`, to specify the 2 versions of **the same package**.

```shell
> BASELINE=<Dependency Representation of baseline>
> TARGET=<Dependency Representation of target>
> julia --project=benchmark benchmark/runbenchmarks.jl --pr --target=$TARGET --baseline=$BASELINE
```

For specification, `Dependency Representation` is similar to the `word` of [add - REPL command - Pkg.jl](https://pkgdocs.julialang.org/v1/repl/#package-commands), described as follows:

| format | example |
| :-: | :-: |
| `<pkg name>` | `Flux` |
| `<pkg name>@<version>` | `NNlib@0.8.20` |
| `<pkg name>#<branch name, commit id>` | `Zygote#master` or `Zygote#2f4937096ee1db4b5a67c1c31fe3ebeab1c96c8c` |
| `<url>` | `https://github.com/FluxML/Optimisers.jl` |
| `<url>#<branch name, commit id>` | `https://github.com/FluxML/Functors.jl#master` |

e.g.

```shell
> BASELINE="https://github.com/FluxML/NNlib.jl#backports-0.8.21"
> TARGET="https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test"
> julia --project=benchmark benchmark/runbenchmarks.jl --pr --target=$TARGET --baseline=$BASELINE
```

#### ii. Multiple Packages

The performance of a package need measured under the condition that other packages and tools remain constant. However, in the case of mutual influence between **multiple packages of different versions**, **2 sets of dependencies** need to be provided simultaneously. As for this scenario, you can use `--baseline` and `--target` as well:

```shell
> BASELINE=<Dependency Representation A1 of baseline>,<Dependency Representation B1 of baseline>,<Dependency Representation C1... of baseline>
> TARGET=<Dependency Representation A2 of target>,<Dependency Representation of B2 target>,<Dependency Representation C2... of target>
> julia --project=benchmark benchmark/runbenchmarks.jl --pr --target=$TARGET --baseline=$BASELINE
```

#### iii. Multiple Sets of Dependencies

Sometimes we need to run benchmarks for multiple sets of dependencies simultaneously. To meet this benchmarking requirements, you can use `--deps-list`:

```shell
> DEPS_LIST=<Dependencies List>
> julia --project=benchmark benchmark/runbenchmarks.jl --cli --deps-list=$DEPS_LIST
```

For specification, `Dependencies List` is a single string that simulates an array, with each element separated by a semicolon. Each element adheres to the format of `Dependency Representation`. However, **Unlike the previous output `result-baseline.json` and `result-target.json`, the output format for this feature is `result-1.json`, `result-2.json`, `result-n.json`...**

e.g.

```shell
> DEPS_LIST="NNlib,Flux;https://github.com/FluxML/NNlib.jl#backports-0.8.21,Flux;https://github.com/skyleaworlder/NNlib.jl#backports-0.8.21,Flux@0.13.12"
> julia --project=benchmark benchmark/runbenchmarks.jl --cli --deps-list=$DEPS_LIST
```

### 2. GitHub Pull Request

TODO

## Command Arguments

### 0. `--pr` / `--cli` / `--cache-setup` / `--merge-reports`

Each argument represents an operation this tool will perform. The corresponding relationship is:

* `--pr`: "benchmark/script/runbenchmarks-pr.jl" You can specify `--target` `--baseline` `--enable` `--disable`
* `--cli`: "benchmark/script/runbenchmarks-cli.jl" You can specify `--deps-list` `--enable` `--disable`
* (**Not recommended, used by GitHub Actions**) `--cache-setup`: "benchmark/script/cachesetup-cli.jl" You can specify `--target` `--baseline`
* (**Not recommended, used by GitHub Actions**) `--merge-reports`: "benchmark/script/mergereports-cli.jl" You can specify `--target` `--baseline` `--push-result` `--push-username` `--push-useremail` `--push-password`

### 1. `--target` / `--baseline` / `--deps-list`

See [Use cases - Single Package](#i-single-package) and [Use cases - Multiple Packages](#ii-multiple-packages).

### 2. `--enable` / `--disable`

Benchmarking always takes amount of time. In order to focus on the targets and reduce the time consumption of our benchmarking tool, the `--enable` and `--disable` options are used to specify **the parts to be included** and **the parts to be excluded** respectively.

```shell
> julia --project=benchmark benchmark/runbenchmarks.jl --cli  \
>   --enable=<ENABLED_PARTS> \
>   --disable=<DISABLED_PARTS> \
>   --deps-list=<Dependencies List>
```

For specification, `Enabled Parts` and `Disabled Parts` have the same format, which is a single string that simulates an array, with each element separated by a semicolon.

`--enable` is used to specify the files that should be included, and by default (`--enable` not specified) all files in the `benchmark/benchmark` are included. `--disable` is used to specify the files that should be excluded, and the default value is an empty string.

More precisely, the granularity of the element of `Enabled Parts` and `Disabled Parts` is currently at the file-level, and supports two levels of files, which means that now **our tool will recognize the name of each file in `benchmark/benchmark` and all the files under `benchmark/benchmark/**` before benchmarking**.

**Each top-level element in `Enabled Parts` and `Disable Parts` should be exactly the name of the file under `benchmark/benchmark`; each second-level element should be the name of the file under the dir that has the same name of top-level file**.

> I don't recommend using `--enable` and `--disable` at the same time. But if you do, `--disable` takes priority over `--enable`.
> 
> e.g. if `--enable` is set "flux,nnlib" while `--disable` is set "nnlib", only benchmarks in "benchmark/benchmark/flux.jl" will be executed.

e.g.

```shell
> DEPS_LIST="https://github.com/FluxML/NNlib.jl#backports-0.8.21,Flux;https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test,Flux@0.13.12"
> # Only Flux-MLP and all NNlib
> julia --project=benchmark benchmark/runbenchmarks.jl --cli --enable="flux(mlp);nnlib" --deps-list=$DEPS_LIST
> # All benchmarks except Flux, NNlib-gemm and NNlib-activations
> julia --project=benchmark benchmark/runbenchmarks.jl --cli --disable="flux;nnlib(gemm,activations)" --deps-list=$DEPS_LIST
> # Only Flux
> julia --project=benchmark benchmark/runbenchmarks.jl --cli --enable="flux;nnlib" --disable="nnlib" --deps-list=$DEPS_LIST
```

### 3. `--fetch-result` / `--push-result` / `--push-username` / `--push-useremail` / `--push-password`

These arguments are only used in `--merge-reports`, not recommended.
