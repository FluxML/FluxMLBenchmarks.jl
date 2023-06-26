# FluxMLBenchmarks

`FluxMLBenchmarks` is a benchmarking tool designed for FluxML community, which allows for the creation of different benchmarking environments by installing different sets of dependencies and comparing the results.

## Use cases

### 1. Command-Line Interface

To observe whether there is a performance difference between two versions of **the same package**, `FluxMLBenchmarks` requires 2 parameters, `$BASELINE_LINK` and `$TARGET_LINK`, to specify the 2 versions of **the same package**.

```shell
> BASELINE_LINK=<link of baseline>
> TARGET_LINK=<link of target>
> julia --project=benchmark benchmark/runbenchmarks.jl $TARGET_LINK $BASELINE_LINK
```

The specification of `LINK` is similar to [add - REPL command - Pkg.jl](https://pkgdocs.julialang.org/v1/repl/#package-commands), described as follows:

* `<pkg name>@<version>`, e.g. `Example@0.5`
* `<pkg name>#<branch name, commit id>`, e.g. `Example#master`, `Example#c37b675`
* `<url>@<version>`, e.g. `https://github.com/JuliaLang/Example.jl@0.5`
* `<url>@<branch name, commit id>`, e.g. `https://github.com/JuliaLang/Example.jl#c37b675`

e.g.

```shell
> BASELINE_LINK="https://github.com/FluxML/NNlib.jl#backports-0.8.21"
> TARGET_LINK="https://github.com/skyleaworlder/NNlib.jl#dummy-benchmark-test"
> julia --project=benchmark benchmark/runbenchmarks.jl $TARGET_LINK $BASELINE_LINK
```

### 2. GitHub Pull Request

TODO
