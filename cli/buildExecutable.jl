using PackageCompiler
using Pkg

Pkg.activate(@__DIR__)
Pkg.instantiate()
Pkg.develop(; path = joinpath(@__DIR__, ".."))



const libName = Sys.isapple() ? "zettel.dylib" : Sys.iswindows() ? "zettel.dll" : "zettel.so"
const libPath = joinpath(@__DIR__, libName)
const precompileFile = joinpath(@__DIR__, "precompile.jl")


@info "building sysimage; writing to: $libPath"
create_sysimage([:Zettel]; project = @__DIR__, precompile_execution_file = precompileFile, sysimage_path = libPath)
@info "✓ sysimage created successfully"
