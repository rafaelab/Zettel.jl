using OrderedCollections
using Zettel

mktempdir() do dir
	bibPath = joinpath(dir, "sample.bib")
	jsonPath = joinpath(dir, "sample.json")
	yamlPath = joinpath(dir, "sample.yaml")
	bibOutPath = joinpath(dir, "sample_out.bib")
	auxPath = joinpath(dir, "sample.aux")
	bblPath = joinpath(dir, "sample.bbl")

	write(bibPath, """
		@article{Einstein1905,
			author = {Einstein, A.},
			title = {Zur Elektrodynamik bewegter Körper},
			journal = {Annalen der Physik},
			year = {1905}
		}
		"""
	)

	bibtexToJson(bibPath, jsonPath)
	jsonToYaml(jsonPath, yamlPath)
	yamlToBibtex(yamlPath, bibOutPath)
	readJsonLibrary(jsonPath)
	readYamlLibrary(yamlPath)
	readBibtexLibrary(bibOutPath)

	write(auxPath, """
		\\relax
		\\citation{Einstein1905}
		\\bibdata{sample}
		\\bibstyle{plain}
		"""
	)
	writeBblFromAux(auxPath; libraryFiles = [yamlPath], outputPath = bblPath)

	entry = ZettelEntry(
		"Einstein1905",
		"article",
		OrderedCollections.OrderedDict{String,String}(
			"author" => "Einstein, A.",
			"title" => "Zur Elektrodynamik bewegter Körper",
			"journal" => "Annalen der Physik",
			"year" => "1905",
		),
	)
	lib = ZettelLibrary([entry])
	writeJsonLibrary(lib, jsonPath)
	writeYamlLibrary(lib, yamlPath)
	writeBibtexLibrary(lib, bibOutPath)
	zettelCLI(args = [bibPath, jsonPath])
	zettelCLI(args = ["convert", jsonPath, yamlPath, "--to", "yaml"])
end
