using Documenter
using Zettel

makedocs(
	sitename = "Zettel.jl",
	authors  = "Rafael Alves Batista (@rafaelab)",
	modules  = [Zettel],
	checkdocs = :exports,
	format   = Documenter.HTML(
		prettyurls = get(ENV, "CI", nothing) == "true",
	),
	pages = [
		"Home"      => "index.md",
		"CLI Guide" => "cli.md",
		"CLI Build" => "juliac.md",
		"API"       => "api.md",
	],
)

deploydocs(
	repo   = "github.com/rafaelab/Zettel.jl.git",
	devbranch = "main",
)
