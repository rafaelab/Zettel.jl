# ----------------------------------------------------------------------------------------------- #
#
@testset "JSON round-trip" begin
	lib = ZettelLibrary([sampleArticle(), sampleBook()])
	tmpfile = tempname() * ".json"

	try
		writeJsonLibrary(lib, tmpfile)
		@test isfile(tmpfile)

		lib2 = readJsonLibrary(tmpfile)
		@test length(lib2) == 2
		@test haskey(lib2, "Einstein1905")
		@test haskey(lib2, "Misner1973")

		e = lib2["Einstein1905"]
		@test getTitle(e) == "Zur Elektrodynamik bewegter Körper"
		@test getYear(e) == "1905"
		@test getDOI(e) == "10.1002/andp.19053221004"
	finally
		isfile(tmpfile) && rm(tmpfile)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX round-trip" begin
	lib = ZettelLibrary([sampleArticle()])
	tmpbib = tempname() * ".bib"

	try
		writeBibtexLibrary(lib, tmpbib)
		@test isfile(tmpbib)

		lib2 = readBibtexLibrary(tmpbib)
		@test length(lib2) ≥ 1
		@test haskey(lib2, "Einstein1905")
		e = lib2["Einstein1905"]
		@test ! isempty(getTitle(e))

	finally
		if isfile(tmpbib)
			rm(tmpbib)
		end
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX TeX/UTF-8 normalization" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		write(inputBib, """
			@article{accented2026,
				author = {{M{\\\"u}ller}, Andr\\'e},
				title = {Caf\\'e and Schr{\\\"o}dinger},
				journal = {Journal of Testing},
				year = {2026}
			}
			"""
		)

		loaded = readBibtexLibrary(inputBib)
		entry = loaded["accented2026"]
		@test getAuthors(entry) == "Müller, André"
		@test getTitle(entry) == "Café and Schrödinger"

		outputBib = joinpath(dir, "output.bib")
		writeBibtexLibrary(loaded, outputBib)
		rebuiltBib = read(outputBib, String)
		@test occursin("\\\"u", rebuiltBib)
		@test occursin("\\'e", rebuiltBib)
	end
end


# ----------------------------------------------------------------------------------------------- #
