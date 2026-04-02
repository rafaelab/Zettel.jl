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


# ----------------------------------------------------------------------------------------------- #
@testset "CLI convert mode" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputYaml = joinpath(dir, "library.yaml")
		outputJson = joinpath(dir, "library.json")
		outputBib = joinpath(dir, "library.bib")
		write(inputBib, TEST_REF)

		code1 = zettelCLI(; args = ["convert", inputBib, outputYaml, "--to", "yaml"])
		@test code1 == 0
		@test isfile(outputYaml)

		code2 = zettelCLI(; args = ["convert", outputYaml, outputJson, "--to", "json"])
		@test code2 == 0
		@test isfile(outputJson)

		code3 = zettelCLI(; args = ["convert", outputJson, outputBib, "--to", "bib", "--from", "json"])
		@test code3 == 0
		@test isfile(outputBib)
	end
end


# ----------------------------------------------------------------------------------------------- #
@testset "Format dispatch" begin
	@test Zettel.parseBibliographyFormat("json") isa Zettel.JsonFormat
	@test Zettel.parseBibliographyFormat("yml") isa Zettel.YamlFormat
	@test Zettel.bibliographyFormat("example.bib") isa Zettel.BibTeXFormat
end
