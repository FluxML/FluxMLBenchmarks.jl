const TUNE_FILE = "benchmark/tune.json"
const TUNE_BRANCH = "benchmark-tuning"

"""
    get_tuning_json()

is used to checkout tune.json from benchmark-tuning branch.
If impossible, retune later in PkgBenchmark.benchmarkpkg.
"""
function get_tuning_json()
    isfile(TUNE_FILE) && (@warn "$TUNE_FILE already exists"; return)
    cmd = pipeline(`git show $TUNE_BRANCH:tune.json`; stdout=TUNE_FILE)
    try
        @info "try to checkout tune.json in branch $TUNE_BRANCH."
        run(cmd)
        return
    catch
        @warn "benchmark-tuning:tune.json not existed"
        isfile(TUNE_FILE) && rm(TUNE_FILE)
    end
end
