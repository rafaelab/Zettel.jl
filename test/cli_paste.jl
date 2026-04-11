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
	@test jsonPayload[:key] == "Einstein1905"
	@test jsonPayload[:type] == "article"

	mktempdir() do dir
		jsonLibraryPath = joinpath(dir, "library.json")
		yamlLibraryPath = joinpath(dir, "library.yaml")
		baseLib = ZettelLibrary([sampleBook()])
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

