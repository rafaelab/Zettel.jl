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
	zettelCLI(; args = [bibPath, jsonPath])
	zettelCLI(; args = ["convert", jsonPath, yamlPath, "--to", "yaml"])

	# Exercise the expensive interactive CLI surfaces so the compiled image covers
	# them: exact-key query (JSON fast path + YAML full load), the pure-Julia `bbl`
	# path on a non-.bib library, and the library-mutating paste/libupdate paths.
	zettelCLI(; args = ["--query", "Einstein1905", "--library", jsonPath], output = IOBuffer())
	zettelCLI(; args = ["--query", "Einstein1905", "--library", yamlPath], output = IOBuffer())
	zettelCLI(; args = ["bbl", bblPath, yamlPath, joinpath(dir, "subset.yaml")], output = IOBuffer())

	mutablePath = joinpath(dir, "mutable.json")
	writeJsonLibrary(lib, mutablePath)
	pastedEntry = """
		@article{Newton1687a,
			author = {Newton, Isaac},
			title = {Principia},
			journal = {Royal Society},
			year = {1687}
		}
		"""
	zettelCLI(; args = ["paste", "--to", "json"], input = IOBuffer(pastedEntry), output = IOBuffer())
	zettelCLI(; args = ["paste", "--library", mutablePath], input = IOBuffer(pastedEntry), output = IOBuffer())
	zettelCLI(; args = ["libupdate", "--library", mutablePath], input = IOBuffer(pastedEntry), output = IOBuffer())
end
