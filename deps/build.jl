Pkg.checkout("Reactive")
cp(joinpath(Pkg.dir("Associations"), "src", "BeetleLog.jl"), joinpath(homedir(), "BeetleLog.jl"), remove_destination = true)
chmod(joinpath(homedir(), "BeetleLog.jl"), 0o775)
