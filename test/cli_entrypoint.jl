module CliEntrypointProbe

using Zettel

include(joinpath(@__DIR__, "..", "cli", "entrypoint.jl"))

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI entrypoint routing" begin
	@test CliEntrypointProbe.isBibRelated(["bbl", "paper.bbl", "library.bib", "used.bib"])
	@test CliEntrypointProbe.isBibRelated(["bbl", "paper.bbl", "library.json", "used.bib"])

	# bbl with no .bib file (e.g. json -> yaml) is pure Julia: it must take the
	# fast compiled path rather than the interpreter fallback.
	@test ! CliEntrypointProbe.isBibRelated(["bbl", "paper.bbl", "library.json", "used.yaml"])
	@test ! CliEntrypointProbe.isBibRelated(["bbl", "paper.bbl", "library.yaml", "used.json"])
end


# ----------------------------------------------------------------------------------------------- #
