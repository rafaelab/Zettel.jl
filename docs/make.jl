using Documenter
using Zettel

makedocs(
	sitename = "Zettel.jl",
	authors  = "rafaelab and contributors",
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
