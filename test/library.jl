# ----------------------------------------------------------------------------------------------- #
#
@testset "ZettelLibrary" begin

	@testset "construction and basic operations" begin
		lib = ZettelLibrary()
		@test length(lib) == 0

		e1 = sampleArticle()
		e2 = sampleBook()
		push!(lib, e1)
		push!(lib, e2)
		@test length(lib) == 2
		@test haskey(lib, "Einstein1905")
		@test haskey(lib, "Misner1973")
		@test ! haskey(lib, "notpresent")
	end

	@testset "getindex" begin
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		e = lib["Einstein1905"]
		@test e.key == "Einstein1905"
	end

	@testset "pop!" begin
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		pop!(lib, "Einstein1905")
		@test ! haskey(lib, "Einstein1905")
		@test length(lib) == 1
	end

	@testset "iterate" begin
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		keysFound = [e.key for e ∈ lib]
		@test "Einstein1905" ∈ keysFound
		@test "Misner1973" ∈ keysFound
	end

	@testset "vector constructor" begin
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		@test length(lib) == 2
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "sort" begin
	# Insert in reverse alphabetical order so sort is non-trivial
	e1 = sampleArticle()  # key: Einstein1905
	e2 = sampleBook()     # key: Misner1973
	lib = ZettelLibrary([e2, e1])

	sorted = sort(lib)
	sortedKeys = collect(keys(sorted))
	@test sortedKeys == sort(sortedKeys)
	@test sortedKeys[1] == "Einstein1905"
	@test sortedKeys[2] == "Misner1973"

	# original is unchanged
	originalKeys = collect(keys(lib))
	@test originalKeys[1] == "Misner1973"
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "loadLibrary / saveLibrary" begin
	lib = ZettelLibrary([sampleArticle(), sampleBook()])

	mktempdir() do dir
		@testset "JSON" begin
			path = joinpath(dir, "lib.json")
			saveLibrary(lib, path)
			@test isfile(path)
			lib2 = loadLibrary(path)
			@test length(lib2) == 2
			@test haskey(lib2, "Einstein1905")
			@test haskey(lib2, "Misner1973")
			@test getTitle(lib2["Einstein1905"]) == getTitle(lib["Einstein1905"])
		end

		@testset "YAML" begin
			path = joinpath(dir, "lib.yaml")
			saveLibrary(lib, path)
			@test isfile(path)
			lib2 = loadLibrary(path)
			@test length(lib2) == 2
			@test haskey(lib2, "Einstein1905")
		end

		@testset "BibTeX" begin
			path = joinpath(dir, "lib.bib")
			saveLibrary(lib, path)
			@test isfile(path)
			lib2 = loadLibrary(path)
			@test length(lib2) ≥ 1
			@test haskey(lib2, "Einstein1905")
		end

		@testset "unknown extension" begin
			@test_throws ArgumentError loadLibrary(joinpath(dir, "lib.txt"))
		end

		@testset "missing file" begin
			@test_throws ArgumentError loadLibrary(joinpath(dir, "nonexistent.json"))
		end
	end
end

# ----------------------------------------------------------------------------------------------- #