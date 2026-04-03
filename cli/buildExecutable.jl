using Pkg

Pkg.activate(@__DIR__)
Pkg.instantiate()
Pkg.develop(; path = joinpath(@__DIR__, ".."))

using PackageCompiler

const SYSIMAGE_BASENAME = Sys.isapple() ? "Zettel.dylib" : Sys.iswindows() ? "Zettel.dll" : "Zettel.so"
const SYSIMAGE_PATH = joinpath(@__DIR__, SYSIMAGE_BASENAME)

create_sysimage(
	[:Zettel];
	project = @__DIR__,
	precompile_execution_file = joinpath(@__DIR__, "precompile.jl"),
	sysimage_path = SYSIMAGE_PATH,
)

println("Wrote sysimage to ", SYSIMAGE_PATH)
