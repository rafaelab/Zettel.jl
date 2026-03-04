# ----------------------------------------------------------------------------------------------- #
@testset "Aux parsing and BBL output" begin
	mktempdir() do dir
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
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
@testset "Aux style selection" begin
	mktempdir() do dir
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
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
@testset "Style ordering" begin
	mktempdir() do dir
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
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
@testset "Full style prints fields" begin
	mktempdir() do dir
		lib = ZettelLibrary([_sampleArticle()])
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
