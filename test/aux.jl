# ----------------------------------------------------------------------------------------------- #
#
@testset "Aux parsing and BBL output" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		libPath = joinpath(dir, "library.json")
		writeJsonLibrary(lib, libPath)

		auxPath = joinpath(dir, "test.aux")
		write(auxPath, """
\\relax
\\citation{Einstein1905,Misner1973}
\\bibdata{library}
\\bibstyle{plain}
""")

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
""")

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
""")

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
""")

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
""")

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
""")

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
""")

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