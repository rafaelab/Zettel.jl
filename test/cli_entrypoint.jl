module CliEntrypointProbe

using Zettel

include(joinpath(@__DIR__, "..", "cli", "entrypoint.jl"))

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI entrypoint routing" begin
	@test CliEntrypointProbe.isBibRelated(["bbl", "paper.bbl", "library.bib", "used.bib"])
	@test CliEntrypointProbe.isBibRelated(["bbl", "paper.bbl", "library.json", "used.bib"])
end


# ----------------------------------------------------------------------------------------------- #
