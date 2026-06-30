# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI paste mode" begin
	pastedBib = """
				@article{Einstein1905,
					year = {1905},
					month = {jan},
					journal = {\\apj},
					title = {Zur Elektrodynamik bewegter Korper},
					author = {Einstein, A.}
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
		printedJsonEntry = JSON3.read(String(take!(outputJsonWithLibrary)))
		@test printedJsonEntry[:key] == "einstein1905a"
		@test printedJsonEntry[:fields][:journal] == "The Astrophysical Journal"
		@test printedJsonEntry[:fields][:month] == "01"
		mergedJsonLib = readJsonLibrary(jsonLibraryPath)
		@test haskey(mergedJsonLib, "einstein1905a")
		@test haskey(mergedJsonLib, "Misner1973")
		@test ! haskey(mergedJsonLib, "Einstein1905")
		@test getJournal(mergedJsonLib["einstein1905a"]) == "The Astrophysical Journal"
		@test getField(mergedJsonLib["einstein1905a"], "month") == "01"

		outputYamlWithLibrary = IOBuffer()
		codeYamlLibrary = zettelCLI(
			; args = ["paste", "--to", "yaml", "--library", yamlLibraryPath],
			input = IOBuffer(pastedBib),
			output = outputYamlWithLibrary,
		)
		@test codeYamlLibrary == 0
		printedYamlEntry = readYamlString(String(take!(outputYamlWithLibrary)))
		@test first(keys(printedYamlEntry)) == "einstein1905a"
		mergedYamlLib = readYamlLibrary(yamlLibraryPath)
		@test haskey(mergedYamlLib, "einstein1905a")
		@test haskey(mergedYamlLib, "Misner1973")
		@test ! haskey(mergedYamlLib, "Einstein1905")
		@test getJournal(mergedYamlLib["einstein1905a"]) == "The Astrophysical Journal"
		@test getField(mergedYamlLib["einstein1905a"], "month") == "01"

		wrongKeyBib = """
					@article{wrong2024z,
						author = {Smith, Jane},
						title = {Generated key entry},
						year = {2024}
					}
					"""
		codeGeneratedJson = zettelCLI(
			; args = ["paste", "--library", jsonLibraryPath],
			input = IOBuffer(wrongKeyBib),
			output = IOBuffer(),
		)
		@test codeGeneratedJson == 0
		mergedGeneratedJsonLib = readJsonLibrary(jsonLibraryPath)
		@test haskey(mergedGeneratedJsonLib, "smith2024a")
		@test ! haskey(mergedGeneratedJsonLib, "wrong2024z")

		fastJsonLibraryPath = joinpath(dir, "fastlibrary.json")
		fastBaseLib = ZettelLibrary([
			ZettelEntry(
				"zeta2024a",
				"article",
				OrderedDict(
					"author" => "Zeta, Zelda",
					"title" => "Existing entry",
					"year" => "2024",
				),
			),
		])
		writeJsonLibrary(fastBaseLib, fastJsonLibraryPath)

		fastPaste = """
			@article{whatever2024z,
				author = {Alpha, Alice},
				title = {Fast append entry},
				year = {2024}
			}
			"""
		codeFastJson = zettelCLI(; args = ["paste", "--library", fastJsonLibraryPath], input = IOBuffer(fastPaste), output = IOBuffer())
		@test codeFastJson == 0
		fastJsonLib = readJsonLibrary(fastJsonLibraryPath)
		@test collect(keys(fastJsonLib)) == ["zeta2024a", "alpha2024a"]
	end
end
