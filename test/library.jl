# ----------------------------------------------------------------------------------------------- #
@testset "ZettelLibrary" begin

	@testset "construction and basic operations" begin
		lib = ZettelLibrary()
		@test length(lib) == 0

		e1 = _sampleArticle()
		e2 = _sampleBook()
		push!(lib, e1)
		push!(lib, e2)
		@test length(lib) == 2
		@test haskey(lib, "Einstein1905")
		@test haskey(lib, "Misner1973")
		@test ! haskey(lib, "notpresent")
	end

	@testset "getindex" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		e = lib["Einstein1905"]
		@test e.key == "Einstein1905"
	end

	@testset "pop!" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		pop!(lib, "Einstein1905")
		@test ! haskey(lib, "Einstein1905")
		@test length(lib) == 1
	end

	@testset "iterate" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		keysFound = [e.key for e ∈ lib]
		@test "Einstein1905" ∈ keysFound
		@test "Misner1973" ∈ keysFound
	end

	@testset "vector constructor" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		@test length(lib) == 2
	end

end
