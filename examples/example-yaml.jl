using Zettel
using OrderedCollections


# ---------------------------------------------------------------------------
# YAML round-trip example

article = ZettelEntry(
	"Einstein1905",
	"article",
	OrderedDict{String, String}(
		"author" => "Einstein, A.",
		"title" => "Zur Elektrodynamik bewegter Körper",
		"journal" => "Annalen der Physik",
		"year" => "1905",
		"volume" => "322",
		"pages" => "891-921",
		"doi" => "10.1002/andp.19053221004",
	),
)

book = ZettelEntry(
	"Misner1973",
	"book",
	OrderedDict{String, String}(
		"author" => "Misner, Charles W. and Thorne, Kip S. and Wheeler, John A.",
		"title" => "Gravitation",
		"publisher" => "W. H. Freeman",
		"year" => "1973",
		"isbn" => "978-0-7167-0344-0",
	),
)

lib = ZettelLibrary([article, book])

yamlFile = tempname() * ".yaml"
bibFile = tempname() * ".bib"
jsonFile = tempname() * ".json"

writeYamlLibrary(lib, yamlFile)
println("YAML written to: $yamlFile")

lib2 = readYamlLibrary(yamlFile)
println("Reloaded from YAML: ", lib2)

writeJsonLibrary(lib, jsonFile)
println("JSON written to: $jsonFile")

jsonToYaml(jsonFile, yamlFile)
println("Converted JSON to YAML: $yamlFile")

yamlToBibtex(yamlFile, bibFile)
println("BibTeX written to: $bibFile")

lib3 = readBibtexLibrary(bibFile)
println("Reloaded from BibTeX: ", lib3)


# ---------------------------------------------------------------------------
# Load the sample YAML fixture shipped with the repository

sampleYaml = joinpath(@__DIR__, "data", "sample.yaml")
sampleLib = readYamlLibrary(sampleYaml)
println("Loaded sample YAML library with ", length(sampleLib), " entries.")
