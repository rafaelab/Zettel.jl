using Pkg
using JuliaC


Pkg.activate(@__DIR__)
Pkg.develop(; path = joinpath(@__DIR__, ".."))
Pkg.instantiate()


const exeName = Sys.iswindows() ? "zettel.exe" : "zettel"
const exeDir = joinpath(@__DIR__, "..", "lib")
const exePath = joinpath(exeDir, exeName)
const entrypoint = joinpath(@__DIR__, "entrypoint.jl")

mkpath(exeDir)

extraFlags = String.(split(get(ENV, "JULIAC_FLAGS", "")))
args = String.(vcat(
	["--project", abspath(@__DIR__), "--output-exe", exeName, abspath(entrypoint)],
	extraFlags,
))

@info "building executable; writing to: $exePath"
cd(exeDir) do
	JuliaC.main(args)
end

isfile(exePath) || error("Executable was not produced at $exePath")
@info "✓ executable created successfully"
