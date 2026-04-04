## Zettel.jl - CLI example
#
# This script demonstrates the command-line entry point directly from Julia.
# It shows:
#   1. BibTeX -> JSON conversion.
#   2. JSON -> YAML conversion with explicit format selection.
#   3. YAML -> BibTeX conversion with inferred input type.
#   4. AUX -> BBL generation using a sample library.

using Zettel


# ---------------------------------------------------------------------------
# 1. Prepare a small BibTeX file

bibFile = tempname() * ".bib"
write(bibFile, """
@article{Einstein1905,
	author = {Einstein, A.},
	title = {Zur Elektrodynamik bewegter K{\"o}rper},
	journal = {Annalen der Physik},
	year = {1905}
}
""")


# ---------------------------------------------------------------------------
# 2. Use the CLI entry point for BibTeX -> JSON

jsonFile = tempname() * ".json"
zettelCLI(args = [bibFile, jsonFile])
println("BibTeX converted to JSON: $jsonFile")


# ---------------------------------------------------------------------------
# 3. Convert JSON -> YAML via the CLI conversion mode

yamlFile = tempname() * ".yaml"
zettelCLI(args = ["convert", jsonFile, yamlFile, "--to", "yaml"])
println("JSON converted to YAML: $yamlFile")


# ---------------------------------------------------------------------------
# 4. Convert YAML -> BibTeX with explicit input type

roundTripBibFile = tempname() * ".bib"
zettelCLI(args = ["convert", yamlFile, roundTripBibFile, "--from", "yaml", "--to", "bib"])
println("YAML converted back to BibTeX: $roundTripBibFile")


# ---------------------------------------------------------------------------
# 5. Generate a bibliography from an AUX file

mktempdir() do dir
	auxFile = joinpath(dir, "workflow.aux")
	bblFile = joinpath(dir, "workflow.bbl")
	libFile = joinpath(@__DIR__, "sample.yaml")

	write(auxFile, """
\\relax
\\citation{Einstein1905,Misner1973}
\\bibdata{sample}
\\bibstyle{plain}
""")

	zettelCLI(args = [auxFile, "-o", bblFile, "-l", libFile])
	println("BBL written to: $bblFile")
end
