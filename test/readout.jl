# ----------------------------------------------------------------------------------------------- #
#
@testset "Single vs multi readouts" begin
	mktempdir() do dir
		entry = sampleArticle()
		libSingle = ZettelLibrary([entry])
		libMulti = ZettelLibrary([sampleArticle(), sampleBook()])

		jsonSingle = joinpath(dir, "single.json")
		jsonMulti = joinpath(dir, "multi.json")
		yamlSingle = joinpath(dir, "single.yaml")
		yamlMulti = joinpath(dir, "multi.yaml")
		bibSingle = joinpath(dir, "single.bib")
		bibMulti = joinpath(dir, "multi.bib")

		writeJsonLibrary(libSingle, jsonSingle)
		writeJsonLibrary(libMulti, jsonMulti)
		writeYamlLibrary(libSingle, yamlSingle)
		writeYamlLibrary(libMulti, yamlMulti)
		writeBibtexLibrary(libSingle, bibSingle)
		writeBibtexLibrary(libMulti, bibMulti)

		# format-specific single-entry readers
		eJson = readJsonEntry(jsonSingle)
		eYaml = readYamlEntry(yamlSingle)
		eBib = readBibtexEntry(bibSingle)

		@test eJson.key == "Einstein1905"
		@test eYaml.key == "Einstein1905"
		@test eBib.key == "Einstein1905"

		@test_throws ArgumentError readJsonEntry(jsonMulti)
		@test_throws ArgumentError readYamlEntry(yamlMulti)
		@test_throws ArgumentError readBibtexEntry(bibMulti)

		# unified dispatch readers
		@test readEntry(JsonFormat(), jsonSingle).key == "Einstein1905"
		@test readEntry(YamlFormat(), yamlSingle).key == "Einstein1905"
		@test readEntry(BibtexFormat(), bibSingle).key == "Einstein1905"

		@test length(readEntries(JsonFormat(), jsonMulti)) == 2
		@test length(readEntries(YamlFormat(), yamlMulti)) == 2
		@test length(readEntries(BibtexFormat(), bibMulti)) == 2
	end
end


# ----------------------------------------------------------------------------------------------- #
