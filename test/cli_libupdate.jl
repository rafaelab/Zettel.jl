# ----------------------------------------------------------------------------------------------- #
#
@testset "CLI libupdate mode" begin
	mktempdir() do dir
		libPath = joinpath(dir, "refs.bib")
		jsonPath = joinpath(dir, "refs.json")
		yamlPath = joinpath(dir, "refs.yaml")
		write(libPath, """
			@article{smith2024a,
				author = {Smith, Jane},
				title = {Existing entry},
				year = {2024}
			}
			@article{auger2015b,
				author = {Doe, John},
				collaboration = {Pierre Auger Collaboration},
				title = {Existing collaboration entry},
				year = {2015}
			}
			"""
		)
		writeJsonLibrary(ZettelLibrary([sampleBook()]), jsonPath)
		writeYamlLibrary(ZettelLibrary([sampleBook()]), yamlPath)

		pastedAuthor = """
			@article{badkey2024z,
				author = {Smith, Jane},
				title = {New author entry},
				journal = {Journal of Testing},
				volume = {10},
				pages = {100-110},
				year = {2024}
			}
			"""
		code1 = zettelCLI(; args = ["libupdate", "--library", libPath], input = IOBuffer(pastedAuthor), output = IOBuffer())
		@test code1 == 0

		lib1 = readBibtexLibrary(libPath)
		@test haskey(lib1, "smith2024b")

		similarPaste = """
			@article{another2024z,
				author = {Smith, Jane},
				title = {New author entry},
				journal = {Journal of Testing},
				volume = {10},
				pages = {100--110},
				year = {2024}
			}
			"""
		@test_logs (:warn, r"similar entry detected") zettelCLI(; args = ["libupdate", "--library", libPath], input = IOBuffer(similarPaste), output = IOBuffer())
		libSimilar = readBibtexLibrary(libPath)
		@test length(libSimilar) == 3

		pastedOnBehalf = """
			@article{whatever2015z,
				author = {Doe, Jane},
				collaboration = {Pierre Auger Collaboration},
				onbehalf = {true},
				title = {On behalf entry},
				year = {2015}
			}
			"""
		codeOnBehalf = zettelCLI(; args = ["libupdate", "--library", libPath], input = IOBuffer(pastedOnBehalf), output = IOBuffer())
		@test codeOnBehalf == 0
		libOnBehalf = readBibtexLibrary(libPath)
		@test haskey(libOnBehalf, "doe2015a")

		mktempdir() do fileDir
			fileStem = joinpath(fileDir, "smith2024c.pdf")
			write(fileStem, "dummy")
			pastedFile = """
				@article{badfilekey2024z,
					author = {Smith, Jane},
					file = {:$fileStem:PDF},
					title = {File key entry},
					year = {2024}
				}
				"""
			codeFile = zettelCLI(; args = ["libupdate", "--library", libPath, "--fileDir", fileDir], input = IOBuffer(pastedFile), output = IOBuffer())
			@test codeFile == 0
			libFile = readBibtexLibrary(libPath)
			@test haskey(libFile, "smith2024c")
		end

		pastedCollab = """
			@article{whatever2026z,
				author = {Doe, Jane},
				collaboration = {Pierre Auger Collaboration},
				title = {New collaboration entry},
				year = {2015}
			}
			"""
		code2 = zettelCLI(; args = ["libupdate", "--library", libPath], input = IOBuffer(pastedCollab), output = IOBuffer())
		@test code2 == 0

		lib2 = readBibtexLibrary(libPath)
		@test haskey(lib2, "auger2015a")

		jsonPaste = """
			@article{wrong2024z,
				author = {Smith, Jane},
				title = {JSON library entry},
				year = {2024}
			}
			"""
		codeJson = zettelCLI(; args = ["libupdate", "--library", jsonPath], input = IOBuffer(jsonPaste), output = IOBuffer())
		@test codeJson == 0
		libJson = readJsonLibrary(jsonPath)
		@test haskey(libJson, "smith2024a")

		yamlPaste = """
			@article{wrong2024y,
				author = {Smith, Jane},
				title = {YAML library entry},
				year = {2024}
			}
			"""
		codeYaml = zettelCLI(; args = ["libupdate", "--library", yamlPath], input = IOBuffer(yamlPaste), output = IOBuffer())
		@test codeYaml == 0
		libYaml = readYamlLibrary(yamlPath)
		@test haskey(libYaml, "smith2024a")

		backups = filter(p -> occursin(r"^refs\.bib\.\d{8}-\d{6}\.bak$", basename(p)), readdir(dir; join = true))
		@test ! isempty(backups)
	end
end
