# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX <-> JSON round-trip" begin
	mktempdir() do dir
		inputBib  = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputBib  = joinpath(dir, "output.bib")
		write(inputBib, TEST_REF)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		convertBibliography(outputJson, outputBib, JsonFormat(), BibtexFormat())

		original = Pybtex.readBibtexDataBase(inputBib)
		rebuilt  = Pybtex.readBibtexDataBase(outputBib)
		origEntry    = Pybtex.getEntry(original, "doe2024")
		rebuiltEntry = Pybtex.getEntry(rebuilt,  "doe2024")

		@test pyconvert(String, origEntry.info.fields["title"]) == pyconvert(String, rebuiltEntry.info.fields["title"])
		@test length(rebuiltEntry.info.persons["author"]) == length(origEntry.info.persons["author"])
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "JSON library record format" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")

		write(inputBib, """
			@article{bertone1938,
				author = {{Bertone}, Gianfranco and Roe, Jane},
				title = {{A} Title},
				collaboration = {ATLAS Collaboration},
				year = {1938}
			}
			"""
		)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		data = JSON3.read(read(outputJson, String))
		@test length(data) == 1
		entry = data[1]

		@test entry[:key] == "bertone1938"
		@test entry[:type] == "article"
		@test entry[:fields][:title] == "{A} Title"
		@test entry[:fields][:author] == ["Bertone, Gianfranco", "Roe, Jane"]
		@test entry[:fields][:collaboration] == ["ATLAS Collaboration"]
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Read Zettel JSON as library" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		write(inputBib, TEST_REF)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		lib = readJsonLibrary(outputJson)

		@test haskey(lib, "doe2024")
		@test getAuthors(lib["doe2024"]) == "Doe, Jane and Roe, John"
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX to JSON decodes TeX escapes" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")

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

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		data = JSON3.read(read(outputJson, String))
		entry = data[1][:fields]

		@test entry[:title] == "Café and Schrödinger"
		@test entry[:author] == ["Müller, André"]
		@test entry[:journal] == "The Astrophysical Journal"
		@test entry[:month] == "01"
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX to JSON decodes all diacritic families" begin
	mktempdir() do dir
		inputBib  = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")

		# one entry per diacritic family; pick representative chars that cover explicit
		# table entries and the generic fallback path (e.g. \v{t} -> ť)
		write(inputBib, """
			@article{diacritics2026,
				author = {Test, Author},
				title = {Accents: \\'a \\`e \\^i {\\\"u} \\~n \\=o \\v{s} \\H{o} \\k{a} \\.{z} \\c{c} \\u{g} \\v{t}},
				year = {2026}
			}
			"""
		)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		data = JSON3.read(read(outputJson, String))
		title = data[1][:fields][:title]

		@test occursin("á", title)   # acute
		@test occursin("è", title)   # grave
		@test occursin("î", title)   # circumflex
		@test occursin("ü", title)   # diaeresis
		@test occursin("ñ", title)   # tilde
		@test occursin("ō", title)   # macron
		@test occursin("š", title)   # caron (explicit)
		@test occursin("ő", title)   # double acute
		@test occursin("ą", title)   # ogonek
		@test occursin("ż", title)   # dot above
		@test occursin("ç", title)   # cedilla
		@test occursin("ğ", title)   # breve
		@test occursin("ť", title)   # caron fallback
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "JSON to BibTeX re-encodes accents to TeX" begin
	mktempdir() do dir
		inputBib   = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputBib  = joinpath(dir, "output.bib")

		write(inputBib, """
			@article{accented2026b,
				author = {{M{\\\"u}ller}, Jos\\'e},
				title = {\\v{S}ar\\v{c}evi\\'c method for Pe\\~na-Garc\\'ia},
				year = {2026}
			}
			"""
		)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		convertBibliography(outputJson, outputBib, JsonFormat(), BibtexFormat())
		rebuilt = read(outputBib, String)

		# accented chars must be re-encoded as TeX in BibTeX output
		@test occursin("\\\"u", rebuilt) || occursin("\\\"U", rebuilt)  # Müller
		@test occursin("\\'e", rebuilt)                                  # José
		@test occursin("\\v{S}", rebuilt) || occursin("\\v{s}", rebuilt) # Šarčević
		@test occursin("\\~n", rebuilt)                                  # Peña
		# no raw non-ASCII should survive into BibTeX
		@test ! occursin("ü", rebuilt)
		@test ! occursin("é", rebuilt)
		@test ! occursin("Š", rebuilt)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX accents round-trip through JSON: author names" begin
	mktempdir() do dir
		inputBib   = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputBib  = joinpath(dir, "output.bib")

		write(inputBib, """
			@article{multilang2024,
				author = {{\\v{S}ar\\v{c}evi\\'c}, N. and {Mu\\~noz}, P. and {J\\o{}rgensen}, K. and {\\H{o}v\\H{a}ri}, T.},
				title = {Multi-language author test},
				year = {2024}
			}
			"""
		)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		data = JSON3.read(read(outputJson, String))
		authors = data[1][:fields][:author]

		@test any(a -> occursin("Šarčević", a), authors)
		@test any(a -> occursin("Muñoz", a), authors)
		@test any(a -> occursin("Jørgensen", a) || occursin("Jørgensen", a), authors)
		@test any(a -> occursin("ővári", a) || occursin("ovari", a) || occursin("ő", a), authors)

		# the re-encoded BibTeX must parse back without error
		convertBibliography(outputJson, outputBib, JsonFormat(), BibtexFormat())
		@test isfile(outputBib)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "BibTeX to JSON keeps surname brace groups intact" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")

		write(inputBib, """
			@article{sarcevic2021,
				author = {{Sahl{\\'e}n}, M. and {{\\v{S}}ar{\\v{c}}evi{\\'c}}, N. and {Schmitz}, K.},
				title = {Accent test},
				year = {2021}
			}
			"""
		)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		data = JSON3.read(read(outputJson, String))
		authors = data[1][:fields][:author]

		@test authors == ["Sahlén, M.", "Šarčević, N.", "Schmitz, K."]
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "externalauthor / collaborationauthor are name lists" begin
	# JSON name lists round-trip through the internal "X and Y" representation.
	jsonEntry = OrderedDict(
		"key" => "list2020a",
		"type" => "article",
		"fields" => OrderedDict(
			"author"              => ["Doe, Jane", "Roe, John"],
			"externalauthor"      => ["Smith, Alan", "Jones, Beth"],
			"collaboration"       => ["ATLAS Collaboration"],
			"collaborationauthor" => ["Kim, Lee", "Park, Sun"],
			"title"               => "A Title",
			"year"                => "2020",
		),
	)

	entry = ZettelEntry(jsonEntry)
	@test getField(entry, "externalauthor") == "Smith, Alan and Jones, Beth"
	@test getField(entry, "collaborationauthor") == "Kim, Lee and Park, Sun"

	structured = Zettel.entryToStructuredDict(entry)
	@test structured["fields"]["externalauthor"] == ["Smith, Alan", "Jones, Beth"]
	@test structured["fields"]["collaborationauthor"] == ["Kim, Lee", "Park, Sun"]
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "ampersand preserved across BibTeX <-> JSON" begin
	mktempdir() do dir
		inputBib   = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputBib  = joinpath(dir, "output.bib")

		write(inputBib, raw"""
			@article{aa2021a,
				author = {Doe, Jane},
				title = {Galaxies in A\&A},
				journal = {A\&A},
				url = {http://x.org/a?b=1\&c=2},
				year = {2021}
			}
			"""
		)

		convertBibliography(inputBib, outputJson, BibtexFormat(), JsonFormat())
		fields = JSON3.read(read(outputJson, String))[1][:fields]
		@test fields[:journal] == "A&A"
		@test fields[:title] == "Galaxies in A&A"
		@test fields[:url] == "http://x.org/a?b=1&c=2"

		convertBibliography(outputJson, outputBib, JsonFormat(), BibtexFormat())
		rebuilt = read(outputBib, String)
		@test occursin("A\\&A", rebuilt)
		@test occursin("b=1\\&c=2", rebuilt)
	end
end


# ----------------------------------------------------------------------------------------------- #
