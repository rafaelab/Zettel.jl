# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX <-> JSON round-trip" begin
	mktempdir() do dir
		inputBib  = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputBib  = joinpath(dir, "output.bib")
		write(inputBib, TEST_REF)

		bibtexToJson(inputBib, outputJson)
		jsonToBibtex(outputJson, outputBib)

		original = Pybtex.readBibtexDataBase(inputBib)
		rebuilt  = Pybtex.readBibtexDataBase(outputBib)
		origEntry    = Pybtex.getEntry(original, "doe2024")
		rebuiltEntry = Pybtex.getEntry(rebuilt,  "doe2024")

		@test pyconvert(String, origEntry.info.fields["title"]) == pyconvert(String, rebuiltEntry.info.fields["title"])
		@test length(rebuiltEntry.info.persons["author"]) == length(origEntry.info.persons["author"])
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "JSON library record format" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")

		write(inputBib, """
			@article{bertone1938,
				author = {{Bertone}, Gianfranco and Roe, Jane},
				title = {{A} Title},
				collaboration = {ATLAS Collaboration},
				year = {1938}
			}
			"""
		)

		bibtexToJson(inputBib, outputJson)
		data = JSON3.read(read(outputJson, String))
		@test length(data) == 1
		entry = data[1]

		@test entry[:key] == "bertone1938"
		@test entry[:type] == "article"
		@test entry[:fields][:title] == "{A} Title"
		@test entry[:fields][:author] == "Bertone, Gianfranco and Roe, Jane"
		@test entry[:fields][:collaboration] == "ATLAS Collaboration"
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Read Zettel JSON as library" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		write(inputBib, TEST_REF)

		bibtexToJson(inputBib, outputJson)
		lib = readJsonLibrary(outputJson)

		@test haskey(lib, "doe2024")
		@test getAuthors(lib["doe2024"]) == "Doe, Jane and Roe, John"
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX to JSON decodes TeX escapes" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")

		write(inputBib, """
			@article{accented2026,
				author = {{M{\\\"u}ller}, Andr\\'e},
				title = {Caf\\'e and Schr{\\\"o}dinger},
				journal = {\\apj},
				month = {jan},
				year = {2026}
			}
			"""
		)

		bibtexToJson(inputBib, outputJson)
		data = JSON3.read(read(outputJson, String))
		entry = data[1][:fields]

		@test entry[:title] == "Café and Schrödinger"
		@test entry[:author] == "Müller, André"
		@test entry[:journal] == "The Astrophysical Journal"
		@test entry[:month] == "01"
	end
end


# ----------------------------------------------------------------------------------------------- #
