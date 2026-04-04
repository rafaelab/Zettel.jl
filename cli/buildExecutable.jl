using Pkg
using JuliaC


Pkg.activate(@__DIR__)
Pkg.develop(; path = joinpath(@__DIR__, ".."))
Pkg.instantiate()


const exeName = Sys.iswindows() ? "zettel.exe" : "zettel"
const exeDir = joinpath(@__DIR__, "..", "bin")
const exePath = joinpath(exeDir, exeName)
const entrypoint = joinpath(@__DIR__, "entrypoint.jl")


extraFlags = String.(split(get(ENV, "JULIAC_FLAGS", "")))
args = String.(vcat(["--project", abspath(@__DIR__), "--output-exe", exeName, abspath(entrypoint)], extraFlags))

@info "building executable; writing to: $exePath"
cd(exeDir) do
	JuliaC.main(args)
end

if ! isfile(exePath)
	throw(ErrorException("Executable was not produced at $(exePath)."))
end
@info "✓ executable created successfully"
