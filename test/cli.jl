# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI bib to json" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		write(inputBib, TEST_REF)

		code = zettelCLI(; args = [inputBib, outputJson])
		@test code == 0
		@test isfile(outputJson)

		data = JSON3.read(read(outputJson, String))
		@test haskey(data, :doe2024)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI convert mode" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputYaml = joinpath(dir, "library.yaml")
		outputJson = joinpath(dir, "library.json")
		outputBib = joinpath(dir, "library.bib")
		write(inputBib, TEST_REF)

		code1 = zettelCLI(; args = ["convert", inputBib, outputYaml, "--to", "yaml"])
		@test code1 == 0
		@test isfile(outputYaml)

		code2 = zettelCLI(; args = ["convert", outputYaml, outputJson, "--to", "json"])
		@test code2 == 0
		@test isfile(outputJson)

		code3 = zettelCLI(; args = ["convert", outputJson, outputBib, "--to", "bib", "--from", "json"])
		@test code3 == 0
		@test isfile(outputBib)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Format dispatch" begin
	@test Zettel.parseBibliographyFormat("json") isa Zettel.JsonFormat
	@test Zettel.parseBibliographyFormat("yml") isa Zettel.YamlFormat
	@test Zettel.bibliographyFormat("example.bib") isa Zettel.BibTeXFormat
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI paste mode" begin
	pastedBib = """
				@article{Einstein1905,
					author = {Einstein, A.},
					title = {Zur Elektrodynamik bewegter Korper},
					journal = {Annalen der Physik},
					year = {1905}
				}
				"""

	outputJson = IOBuffer()
	codeJson = zettelCLI(; args = ["paste", "--to", "json"], input = IOBuffer(pastedBib), output = outputJson)
	@test codeJson == 0
	jsonPayload = JSON3.read(String(take!(outputJson)))
	@test haskey(jsonPayload, :Einstein1905)
	@test jsonPayload[:Einstein1905][:entryType] == "article"

	mktempdir() do dir
		jsonLibraryPath = joinpath(dir, "library.json")
		yamlLibraryPath = joinpath(dir, "library.yaml")
		baseLib = ZettelLibrary([_sampleBook()])
		writeJsonLibrary(baseLib, jsonLibraryPath)
		writeYamlLibrary(baseLib, yamlLibraryPath)

		outputJsonWithLibrary = IOBuffer()
		codeJsonLibrary = zettelCLI(
			; args = ["paste", "--to", "json", "--library", jsonLibraryPath],
			input = IOBuffer(pastedBib),
			output = outputJsonWithLibrary,
		)
		@test codeJsonLibrary == 0
		mergedJsonLib = readJsonLibrary(jsonLibraryPath)
		@test collect(keys(mergedJsonLib.entries)) == ["Einstein1905", "Misner1973"]

		outputYamlWithLibrary = IOBuffer()
		codeYamlLibrary = zettelCLI(
			; args = ["paste", "--to", "yaml", "--library", yamlLibraryPath],
			input = IOBuffer(pastedBib),
			output = outputYamlWithLibrary,
		)
		@test codeYamlLibrary == 0
		mergedYamlLib = readYamlLibrary(yamlLibraryPath)
		@test collect(keys(mergedYamlLib.entries)) == ["Einstein1905", "Misner1973"]
	end
end

# ----------------------------------------------------------------------------------------------- #