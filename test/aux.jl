# ----------------------------------------------------------------------------------------------- #
#
@testset "Aux parsing and BBL output" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		auxPath = joinpath(dir, "test.aux")
		write(auxPath, 
			"""
			\\relax
			\\citation{Einstein1905,Misner1973}
			\\bibdata{library}
			\\bibstyle{plain}
			"""
		)

		bblPath = joinpath(dir, "test.bbl")
		result = writeBblFromAux(auxPath; outputPath = bblPath)

		@test isfile(bblPath)
		text = read(bblPath, String)
		@test occursin("\\bibitem{Einstein1905}", text)
		@test occursin("Einstein", text)
		@test isempty(result.absent)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Aux style selection" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		auxPath = joinpath(dir, "test.aux")
		write(auxPath, """
			\\relax
			\\citation{Einstein1905,Misner1973}
			\\bibdata{library}
			\\bibstyle{alpha}
			"""
		)

		bblPath = joinpath(dir, "test.bbl")
		writeBblFromAux(auxPath; outputPath = bblPath)
		text = read(bblPath, String)
		@test occursin("\\bibitem[Ein05]{Einstein1905}", text)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Style ordering" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		auxPath = joinpath(dir, "test.aux")
		write(auxPath, """
			\\relax
			\\citation{Misner1973,Einstein1905}
			\\bibdata{library}
			\\bibstyle{unsrt}
			"""
		)

		bblPath = joinpath(dir, "test.bbl")
		writeBblFromAux(auxPath; outputPath = bblPath)
		text = read(bblPath, String)
		@test findfirst("Misner1973", text) < findfirst("Einstein1905", text)

		writeBblFromAux(auxPath; outputPath = bblPath, style = "plain")
		text2 = read(bblPath, String)
		@test findfirst("Einstein1905", text2) < findfirst("Misner1973", text2)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Full style prints fields" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		auxPath = joinpath(dir, "test.aux")
		write(auxPath, """
			\\relax
			\\citation{Einstein1905}
			\\bibdata{library}
			\\bibstyle{full}
			"""
		)

		bblPath = joinpath(dir, "test.bbl")
		writeBblFromAux(auxPath; outputPath = bblPath)
		text = read(bblPath, String)
		@test occursin("doi:", text)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Aux resolves YAML libraries" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle()])
		libPath = joinpath(dir, "library.yaml")
		writeYamlLibrary(lib, libPath)

		auxPath = joinpath(dir, "test.aux")
		write(auxPath, """
			\\relax
			\\citation{Einstein1905}
			\\bibdata{library}
			\\bibstyle{plain}
			"""
		)

		bblPath = joinpath(dir, "test.bbl")
		result = writeBblFromAux(auxPath; outputPath = bblPath)
		@test isfile(bblPath)
		@test isempty(result.absent)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Parse BBL keys" begin
	mktempdir() do dir
		bblPath = joinpath(dir, "paper.bbl")
		write(bblPath, """
			\\begin{thebibliography}{2}
			\\bibitem[{Einstein(1905)}]{Einstein1905}
			Einstein, A. (1905).
			\\bibitem{Misner1973}
			Misner, C. (1973).
			\\bibitem[{Einstein(1905)}]{Einstein1905}
			Duplicate should be ignored.
			\\end{thebibliography}
			"""
		)

		keys = parseBblKeys(bblPath)
		@test keys == ["Einstein1905", "Misner1973"]
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Write BibTeX subset from BBL" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		bblPath = joinpath(dir, "paper.bbl")
		write(bblPath, """
			\\begin{thebibliography}{2}
			\\bibitem[{Einstein(1905)}]{Einstein1905}
			Einstein, A. (1905).
			\\bibitem{missing1999z}
			Nobody (1999).
			\\end{thebibliography}
			"""
		)

		outPath = joinpath(dir, "used.bib")
		result = writeBibFromBbl(bblPath, libPath, outPath)

		@test result.present == ["Einstein1905"]
		@test result.absent == ["missing1999z"]
		@test isfile(outPath)
		text = read(outPath, String)
		@test occursin("Einstein1905", text)
		@test ! occursin("Misner1973", text)

		# CLI entry point
		out = IOBuffer()
		code = zettelCLI(; args = ["bbl", bblPath, libPath, outPath], output = out)
		@test code == 0
		msg = String(take!(out))
		@test occursin("Extracted 1 entries", msg)
		@test occursin("missing keys: missing1999z", msg)

		@test_throws ArgumentError zettelCLI(; args = ["bbl", bblPath, libPath])
		@test_throws ArgumentError zettelCLI(; args = ["bbl", joinpath(dir, "nope.bbl"), libPath, outPath])
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Write BibTeX subset from BBL — BibTeX master" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.bib")
		writeBibtexLibrary(lib, libPath)

		bblPath = joinpath(dir, "paper.bbl")
		write(bblPath, """
			\\begin{thebibliography}{2}
			\\bibitem[{Einstein(1905)}]{Einstein1905}
			Einstein, A. (1905).
			\\bibitem{missing1999z}
			Nobody (1999).
			\\end{thebibliography}
			"""
		)

		# Cited-only fast path (BibTeX master) matches the full-load path exactly.
		keys = parseBblKeys(bblPath)
		fast = Zettel._collectCitedEntriesFast(BibtexFormat(), libPath, keys)
		@test ! isnothing(fast)
		whole = Zettel._collectCitedEntriesWholeLoad(libPath, keys)
		@test fast[2] == whole[2] == ["Einstein1905"]
		@test fast[3] == whole[3] == ["missing1999z"]
		@test entryToString(fast[1]["Einstein1905"], BibtexFormat()) == entryToString(whole[1]["Einstein1905"], BibtexFormat())

		outPath = joinpath(dir, "used.bib")
		result = writeBibFromBbl(bblPath, libPath, outPath)
		@test result.present == ["Einstein1905"]
		@test result.absent == ["missing1999z"]
		text = read(outPath, String)
		@test occursin("Einstein1905", text)
		@test ! occursin("Misner1973", text)

		# The BibTeX cited-only scan is in-process (not tool-gated), so it still works and the CLI
		# result is unchanged even when the external tools are made unavailable.
		withenv("ZETTEL_TOOLS_DIR" => joinpath(dir, "no-such-tools")) do
			@test ! isnothing(Zettel._collectCitedEntriesFast(BibtexFormat(), libPath, keys))
			fallbackPath = joinpath(dir, "used_fallback.bib")
			r2 = writeBibFromBbl(bblPath, libPath, fallbackPath)
			@test r2.present == ["Einstein1905"]
			@test r2.absent == ["missing1999z"]
		end
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "findEntryByKey degrades gracefully without tools" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		bibPath = joinpath(dir, "lib.bib")
		yamlPath = joinpath(dir, "lib.yaml")
		writeBibtexLibrary(lib, bibPath)
		writeYamlLibrary(lib, yamlPath)

		withenv("ZETTEL_TOOLS_DIR" => joinpath(dir, "no-such-tools")) do
			@test ! Zettel.extractionAvailable(BibtexFormat())
			@test Zettel.extractEntryWithTool(BibtexFormat(), bibPath, "Einstein1905") === :unavailable

			bibEntry = findEntryByKey(bibPath, "Einstein1905")
			@test ! isnothing(bibEntry) && bibEntry.key == "Einstein1905"
			@test isnothing(findEntryByKey(bibPath, "absent2000a"))

			yamlEntry = findEntryByKey(yamlPath, "Einstein1905")
			@test ! isnothing(yamlEntry) && yamlEntry.key == "Einstein1905"
			@test isnothing(findEntryByKey(yamlPath, "absent2000a"))
		end
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BBL and AUX status messages" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		bblPath = joinpath(dir, "paper.bbl")
		write(bblPath, """
			\\begin{thebibliography}{1}
			\\bibitem{Einstein1905}
			Einstein, A. (1905).
			\\end{thebibliography}
			"""
		)

		outPath = joinpath(dir, "used.bib")
		writeBibFromBbl(bblPath, libPath, outPath)
		@test isfile(outPath)
	end

	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		auxPath = joinpath(dir, "paper.aux")
		bblPath = joinpath(dir, "paper_out.bbl")
		write(auxPath, """
			\\relax
			\\citation{Einstein1905}
			\\bibdata{library}
			\\bibstyle{plain}
			"""
		)

		output = IOBuffer()
		zettelCLI(; args = [auxPath, "--library", libPath, "--output", bblPath], output = output)
		text = String(take!(output))
		@test occursin("Wrote $(bblPath) with 1 entries.", text)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
