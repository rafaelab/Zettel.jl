# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI doi mode argument checks" begin
	@test_throws ArgumentError zettelCLI(; args = ["doi"])
	@test_throws ArgumentError zettelCLI(; args = ["doi", "--mailto", "user@example.org"])
	@test_throws ArgumentError zettelCLI(; args = ["doi", "10.1000/test", "--unknown"])
	@test_throws ArgumentError zettelCLI(; args = ["doi", "10.1000/test", "--source", "unknown", "--mailto", "user@example.org"])
	@test_throws ArgumentError zettelCLI(; args = ["doi", "10.1000/test", "--source"])
	@test_throws ArgumentError zettelCLI(; args = ["10.1000/test", "--source", "unknown"])
end

