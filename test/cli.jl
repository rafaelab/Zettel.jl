# ----------------------------------------------------------------------------------------------- #
@testset "CLI bib to json" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		write(inputBib, TEST_REF)

		code = zettelCLI(; args = [inputBib, outputJson])
		@test code == 0
		@test isfile(outputJson)

		data = JSON3.read(read(outputJson, String))
		@test haskey(data, :doe2024)
	end
end
