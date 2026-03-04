# ----------------------------------------------------------------------------------------------- #
@testset "JSON round-trip" begin
	lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
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
@testset "BibTeX round-trip" begin
	lib = ZettelLibrary([_sampleArticle()])
	tmpbib = tempname() * ".bib"

	try
		writeBibTeX(lib, tmpbib)
		@test isfile(tmpbib)

		lib2 = readBibTeX(tmpbib)
		@test length(lib2) ≥ 1
		@test haskey(lib2, "Einstein1905")
		e = lib2["Einstein1905"]
		@test ! isempty(getTitle(e))

	finally
		isfile(tmpbib) && rm(tmpbib)
	end
end
