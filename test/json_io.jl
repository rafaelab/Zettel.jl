# ----------------------------------------------------------------------------------------------- #
@testset "BibTeX <-> JSON conversion" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputBib = joinpath(dir, "output.bib")

		write(inputBib, TEST_REF)

		bibTeXToJson(inputBib, outputJson)
		jsonToBibTeX(outputJson, outputBib)

		original = Pybtex.readBibtexDataBase(inputBib)
		rebuilt = Pybtex.readBibtexDataBase(outputBib)
		originalEntry = Pybtex.getEntry(original, "doe2024")
		rebuiltEntry = Pybtex.getEntry(rebuilt, "doe2024")

		for field ∈ Pybtex.getAllFields(originalEntry)
			@test Pybtex.hasField(rebuiltEntry, field)
			@test pyconvert(String, originalEntry.info.fields[field]) == pyconvert(String, rebuiltEntry.info.fields[field])
		end
		@test length(collect(Pybtex.getAllFields(rebuiltEntry))) == length(collect(Pybtex.getAllFields(originalEntry)))
		@test length(rebuiltEntry.info.persons["author"]) == length(originalEntry.info.persons["author"])

	end
end


# ----------------------------------------------------------------------------------------------- #
@testset "Zettel JSON format" begin
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
""")

		bibTeXToJson(inputBib, outputJson)
		data = JSON3.read(read(outputJson, String))
		entry = data[:bertone1938]

		@test entry[:title] == "{A} Title"
		@test haskey(entry, :author)
		@test entry[:author][1][:first] == "Gianfranco"
		@test entry[:author][1][:last] == "Bertone"
		@test ! haskey(entry[:author][1], :middle)

		@test haskey(entry, :collaboration)
		@test entry[:collaboration][1][:name] == "ATLAS Collaboration"
	end
end


# ----------------------------------------------------------------------------------------------- #
@testset "Read Zettel JSON as library" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		write(inputBib, TEST_REF)

		bibTeXToJson(inputBib, outputJson)
		lib = readJsonLibrary(outputJson)

		@test haskey(lib, "doe2024")
		@test getAuthors(lib["doe2024"]) == "Doe, Jane and Roe, John"
	end
end
