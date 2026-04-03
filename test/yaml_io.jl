# ----------------------------------------------------------------------------------------------- #
#
@testset "JSON <-> YAML conversion" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputYaml = joinpath(dir, "library.yaml")
		outputBib = joinpath(dir, "output.bib")

		write(inputBib, TEST_REF)
		bibTeXToJson(inputBib, outputJson)
		jsonToYaml(outputJson, outputYaml)
		yamlToBibTeX(outputYaml, outputBib)

		@test isfile(outputYaml)
		@test isfile(outputBib)

		original = Pybtex.readBibtexDataBase(inputBib)
		rebuilt = Pybtex.readBibtexDataBase(outputBib)
		originalEntry = Pybtex.getEntry(original, "doe2024")
		rebuiltEntry = Pybtex.getEntry(rebuilt, "doe2024")
		@test pyconvert(String, originalEntry.info.fields["title"]) == pyconvert(String, rebuiltEntry.info.fields["title"])
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "YAML library read/write" begin
	mktempdir() do dir
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		yamlPath = joinpath(dir, "library.yaml")
		writeYamlLibrary(lib, yamlPath)
		lib2 = readYamlLibrary(yamlPath)

		@test length(lib2) == 2
		@test haskey(lib2, "Einstein1905")
		@test haskey(lib2, "Misner1973")
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Sample YAML fixture" begin
	sampleYaml = joinpath(@__DIR__, "..", "examples", "sample.yaml")
	lib = readYamlLibrary(sampleYaml)
	@test haskey(lib, "Einstein1905")
	@test haskey(lib, "Misner1973")
	@test getJournal(lib["Einstein1905"]) == "Annalen der Physik"
end


# ----------------------------------------------------------------------------------------------- #