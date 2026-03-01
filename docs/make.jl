using Documenter
using Zettel
using Pybtex

makedocs(
	sitename = "Zettel.jl",
	authors  = "Rafael Alves Batista (@rafaelab)",
	modules  = [Zettel],
	format   = Documenter.HTML(
		prettyurls = get(ENV, "CI", nothing) == "true",
	),
	pages = [
		"Home"      => "index.md",
		"API"       => "api.md",
	],
)

deploydocs(
	repo   = "github.com/rafaelab/Zettel.jl.git",
	devbranch = "main",
)
