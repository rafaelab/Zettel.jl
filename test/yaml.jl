# ----------------------------------------------------------------------------------------------- #
#
@testset "JSON <-> YAML round-trip" begin
	mktempdir() do dir
		inputBib   = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputYaml = joinpath(dir, "library.yaml")
		outputBib  = joinpath(dir, "output.bib")
		write(inputBib, TEST_REF)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		convertBibliography(outputJson, outputYaml, JsonFormat(), YamlFormat())
		convertBibliography(outputYaml, outputBib, YamlFormat(), BibtexFormat())

		@test isfile(outputYaml)
		@test isfile(outputBib)

		original = Pybtex.readBibtexDataBase(inputBib)
		rebuilt  = Pybtex.readBibtexDataBase(outputBib)
		origEntry    = Pybtex.getEntry(original, "doe2024")
		rebuiltEntry = Pybtex.getEntry(rebuilt,  "doe2024")
		@test pyconvert(String, origEntry.info.fields["title"]) == pyconvert(String, rebuiltEntry.info.fields["title"])
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "YAML library read/write" begin
	mktempdir() do dir
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		yamlPath = joinpath(dir, "library.yaml")
		writeYamlLibrary(lib, yamlPath)
		lib2 = readYamlLibrary(yamlPath)

		@test length(lib2) == 2
		@test haskey(lib2, "Einstein1905")
		@test haskey(lib2, "Misner1973")
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Sample YAML fixture" begin
	sampleYaml = joinpath(@__DIR__, "..", "examples", "data", "references.yml")
	lib = readYamlLibrary(sampleYaml)
	@test haskey(lib, "einstein1905a")
	@test haskey(lib, "friedmann1922a")
	@test getJournal(lib["einstein1905a"]) == "Annalen der Physik"
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX to YAML decodes TeX escapes" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputYaml = joinpath(dir, "library.yaml")
		write(inputBib, """
			@article{accented2026,
				author = {{M{\\\"u}ller}, Andr\\'e},
				title = {Caf\\'e and Schr{\\\"o}dinger},
				journal = {\\apj},
				month = {jan},
				year = {2026}
			}
			"""
		)

		convertBibliography(inputBib, outputYaml, BibtexFormat(), YamlFormat())
		yamlText = read(outputYaml, String)
		@test occursin("Café and Schrödinger", yamlText)
		@test occursin("André", yamlText)
		@test occursin("Müller", yamlText)
		@test occursin("The Astrophysical Journal", yamlText)
		@test occursin("month: '01'", yamlText) || occursin("month: \"01\"", yamlText) || occursin("month: 01", yamlText)
		@test ! occursin("\\\"o", yamlText)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX to YAML decodes all diacritic families" begin
	mktempdir() do dir
		inputBib   = joinpath(dir, "input.bib")
		outputYaml = joinpath(dir, "library.yaml")

		write(inputBib, """
			@article{diacritics2026yaml,
				author = {Test, Author},
				title = {Accents: \\'a \\`e \\^i {\\\"u} \\~n \\=o \\v{s} \\H{o} \\k{a} \\.{z} \\c{c} \\u{g} \\v{t}},
				year = {2026}
			}
			"""
		)

		convertBibliography(inputBib, outputYaml, BibtexFormat(), YamlFormat())
		yamlText = read(outputYaml, String)

		@test occursin("á", yamlText)   # acute
		@test occursin("è", yamlText)   # grave
		@test occursin("î", yamlText)   # circumflex
		@test occursin("ü", yamlText)   # diaeresis
		@test occursin("ñ", yamlText)   # tilde
		@test occursin("ō", yamlText)   # macron
		@test occursin("š", yamlText)   # caron (explicit)
		@test occursin("ő", yamlText)   # double acute
		@test occursin("ą", yamlText)   # ogonek
		@test occursin("ż", yamlText)   # dot above
		@test occursin("ç", yamlText)   # cedilla
		@test occursin("ğ", yamlText)   # breve
		@test occursin("ť", yamlText)   # caron fallback
		# no TeX escapes must leak into YAML
		@test ! occursin("\\'", yamlText)
		@test ! occursin("\\\"", yamlText)
		@test ! occursin("\\v{", yamlText)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX accents round-trip through YAML" begin
	mktempdir() do dir
		inputBib   = joinpath(dir, "input.bib")
		outputYaml = joinpath(dir, "library.yaml")
		outputBib  = joinpath(dir, "output.bib")

		write(inputBib, """
			@article{rt2024,
				author = {{\\v{S}ar\\v{c}evi\\'c}, N. and {P\\'erez}, A.},
				title = {\\\"Uber Elektrodynamik und Schr\\\"odinger},
				journal = {\\mnras},
				year = {2024}
			}
			"""
		)

		convertBibliography(inputBib, outputYaml, BibtexFormat(), YamlFormat())
		yamlText = read(outputYaml, String)

		# decoded Unicode must appear in YAML
		@test occursin("Šarčević", yamlText)
		@test occursin("Pérez", yamlText)
		@test occursin("Über Elektrodynamik und Schrödinger", yamlText)
		@test occursin("Monthly Notices", yamlText)

		# round-trip back to BibTeX and verify it parses
		convertBibliography(outputYaml, outputBib, YamlFormat(), BibtexFormat())
		rebuiltBib = read(outputBib, String)

		# re-encoded TeX must be present in the BibTeX output
		@test occursin("\\\"u", rebuiltBib) || occursin("\\\"U", rebuiltBib)
		@test occursin("\\'e", rebuiltBib)
		# no raw accented Unicode should survive into BibTeX values
		@test ! occursin("ü", rebuiltBib)
		@test ! occursin("Š", rebuiltBib)
	end
end


# ----------------------------------------------------------------------------------------------- #
