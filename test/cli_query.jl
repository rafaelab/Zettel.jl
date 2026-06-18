# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI query mode argument checks" begin
	@test_throws ArgumentError zettelCLI(; args = ["--query"])
	@test_throws ArgumentError zettelCLI(; args = ["--query", "doe2024"])
	@test_throws ArgumentError zettelCLI(; args = ["--query", "doe2024", "--unknown"])
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI query mode output" begin
	mktempdir() do dir
		libPath = joinpath(dir, "library.json")

		regularFields = OrderedDict{String, String}(
			"author" => "Doe, Jane and Roe, John",
			"title" => "A Sample Entry",
			"journal" => "Journal of Testing",
			"year" => "2024",
			"volume" => "12",
			"number" => "3",
			"eprint" => "2401.01234",
			"archivePrefix" => "arXiv",
			"doi" => "10.1000/example",
		)
		collaborationFields = OrderedDict{String, String}(
			"author" => "Doe, Jane and Roe, John",
			"title" => "Collaboration Paper",
			"journal" => "Physics Letters",
			"year" => "2025",
			"volume" => "99",
			"collaboration" => "{LIGO Scientific Collaboration}",
		)
		onbehalfFields = OrderedDict{String, String}(
			"author" => "Doe, Jane and Roe, John",
			"title" => "On Behalf Study",
			"journal" => "Physics Letters",
			"year" => "2026",
			"volume" => "100",
			"collaboration" => "{LIGO Scientific Collaboration}",
			"onbehalf" => "true",
		)

		lib = ZettelLibrary([
			ZettelEntry("doe2024a", "article", regularFields),
			ZettelEntry("ligo2025a", "article", collaborationFields),
			ZettelEntry("doe2026a", "article", onbehalfFields),
		])
		writeJsonLibrary(lib, libPath)

		missingOutput = IOBuffer()
		@test_logs (:warn, r"bibkey not found") zettelCLI(; args = ["--query", "missing2024a", "--library", libPath], output = missingOutput)

		regularOutput = IOBuffer()
		code1 = zettelCLI(; args = ["--query", "doe2024a", "--library", libPath], output = regularOutput)
		@test code1 == 0
		regularText = String(take!(regularOutput))
		@test occursin("\"A Sample Entry\"", regularText)
		@test occursin("J. Doe, J. Roe", regularText)
		@test occursin("Journal of Testing, 2024, 12, 3", regularText)
		@test occursin("arXiv:2401.01234", regularText)
		@test occursin("doi: 10.1000/example", regularText)
		@test occursin("bibkey: doe2024a", regularText)

		collaborationOutput = IOBuffer()
		code2 = zettelCLI(; args = ["--query", "ligo2025a", "--library", libPath], output = collaborationOutput)
		@test code2 == 0
		collaborationText = String(take!(collaborationOutput))
		@test occursin("LIGO Scientific Collaboration", collaborationText)
		@test ! occursin("J. Doe, J. Roe", collaborationText)

		onbehalfOutput = IOBuffer()
		code3 = zettelCLI(; args = ["--query", "doe2026a", "--library", libPath], output = onbehalfOutput)
		@test code3 == 0
		onbehalfText = String(take!(onbehalfOutput))
		@test occursin("J. Doe et al. for LIGO Scientific Collaboration", onbehalfText)
	end
end
