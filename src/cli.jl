export
	zettelCLI


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	usageCLI(; io::IO = stdout)

Print the command-line usage/help text to `io` (defaults to stdout). 
Used by the CLI when `-h`/`--help` is requested or when no arguments are provided.
"""
function usageCLI(; io::IO = stdout)
	println(io, "# Usage")
	println(io, "  zettel convert <input> <output> [--from <fmt>] --to <fmt>")
	println(io, "  zettel doi     <doi> [--source <name>] [--to <fmt>] [--output <file>] [--mailto <email>] [--plus-token <token>]")
	println(io, "  zettel --query <bibkey> --library <file>")
	println(io, "  zettel bbl     <bblfile> <input.bib> <output.bib>")
	println(io, "  zettel paste   [--to <fmt>] --library <file>")
	println(io, "  zettel paste   --to <fmt>")
	println(io, "  zettel libupdate --library <file> [--key <key>] [--fileDir <dir>]")
	println(io, "  zettel <auxfile> [options]")
	println(io, "")
	println(io, "# Commands")
	println(io, "  convert        Convert a bibliography file between formats (bib, json, yaml).")
	println(io, "  doi            Fetch a DOI from a metadata source and emit one ZettelEntry (bib, json, yaml).")
	println(io, "  --query        Query one bibkey in a library and print a compact human-readable summary.")
	println(io, "  bbl            Extract the entries cited in a .bbl from a library into a new .bib (used keys only).")
	println(io, "  paste          Read a BibTeX entry from stdin; print it and/or add it to a library.")
	println(io, "  libupdate      Read one BibTeX entry from stdin, generate/update key, backup library, and insert it.")
	println(io, "")
	println(io, "# Options (convert)")
	println(io, "  -f, --from <fmt>       Input format (inferred from extension when omitted)")
	println(io, "  -t, --to   <fmt>       Output format (required)")
	println(io, "")
	println(io, "# Options (doi)")
	println(io, "      --source <name>    Metadata source (default: crossref; supported: $(join(doiSources(), ", ")))")
	println(io, "  -t, --to <fmt>         Output format for the fetched entry (bib, json, yaml; default: bib)")
	println(io, "  -o, --output <file>    Write output to file instead of stdout")
	println(io, "  -m, --mailto <email>   Contact email for Crossref polite access (crossref source)")
	println(io, "      --plus-token <tok> Crossref Metadata Plus API token (crossref source, optional)")
	println(io, "")
	println(io, "# Options (--query)")
	println(io, "      --query <bibkey>   Citation key to query in the target library")
	println(io, "  -l, --library <file>   Source library (.bib, .json, .yaml/.yml)")
	println(io, "")
	println(io, "# Options (bbl)")
	println(io, "  <bblfile>              LaTeX .bbl file providing the cited keys")
	println(io, "  <input.bib>            Master library to pull entries from (.bib, .json, .yaml/.yml)")
	println(io, "  <output.bib>           Destination for the extracted subset (format from extension)")
	println(io, "")
	println(io, "# Options (paste)")
	println(io, "  -t, --to   <fmt>       Print the entry in this format to stdout (bib, json, yaml)")
	println(io, "  -l, --library <file>   Add the entry to this library and rewrite it")
	println(io, "")
	println(io, "# Options (libupdate)")
	println(io, "  -l, --library <file>   Target library to update (.bib, .json, .yaml/.yml)")
	println(io, "      --key <key>        Force key instead of generated suggestion")
	println(io, "      --fileDir <dir>    File lookup directory (default: <libraryDir>/files)")
	println(io, "")
	println(io, "# Options (aux mode)")
	println(io, "  -l, --library <file>   Library file (repeatable; inferred from \\bibdata when omitted)")
	println(io, "  -o, --output <file>    Output .bbl path (default: <auxfile>.bbl)")
	println(io, "  -s, --style <name>     Bibliography style (default: auto)")
	println(io, "")
	println(io, "  -h, --help             Show this message")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	zettelCLI(; args, input, output)

Command-line entry point for `zettel`.

# Commands
- `zettel convert <input> <output> [--from <fmt>] --to <fmt>`: convert between bib/json/yaml.
- `zettel paste [--to <fmt>] [--library <file>]`: read a BibTeX entry from stdin, print it in the requested format and/or add it to a library.
- `zettel <auxfile> [options]`: generate a `.bbl` file from a `.aux` file.
"""
function zettelCLI(; args = ARGS, input::IO = stdin, output::IO = stdout)
	if isempty(args) || ("-h" ∈ args) || ("--help" ∈ args)
		usageCLI(io = output)
		return 0
	end

	if args[1] == "convert"
		runConvertCLI(args[2 : end])
		return 0
	end

	if args[1] == "doi"
		runDoiCLI(args[2 : end]; output = output)
		return 0
	end

	if args[1] == "--query"
		runQueryCLI(args[2 : end]; output = output)
		return 0
	end

	if args[1] == "bbl"
		runBblCLI(args[2 : end]; output = output)
		return 0
	end

	# shorthand DOI mode: zettel <doi> [doi-options]
	if isPossibleDoiInvocation(args)
		runDoiCLI(args; output = output)
		return 0
	end

	# shorthand: zettel <input> <output>  (formats inferred from extensions)
	if length(args) == 2 && ! startswith(args[1], "-") && ! startswith(args[2], "-")
		convertBibliography(args[1], args[2], bibliographyFormat(args[1]), bibliographyFormat(args[2]))
		return 0
	end

	if args[1] == "paste"
		runPasteCLI(args[2 : end]; input = input, output = output)
		return 0
	end

	if args[1] == "libupdate"
		runLibUpdateCLI(args[2 : end]; input = input, output = output)
		return 0
	end

	# aux mode
	runAuxCLI(args; output = output)
	
	return 0
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runDoiCLI(args::Vector{String}; output::IO = stdout)

Handle the `doi` subcommand and fetch one entry from a DOI metadata source.
Expected form:
- `doi <doi> [--source <name>] [--to <fmt>] [--output <file>] [--mailto <email>] [--plus-token <token>]`
For source `crossref`, polite access requires a contact email via `--mailto` or `CROSSREF_MAILTO`.
"""
function runDoiCLI(args::Vector{String}; output::IO = stdout)
	doi = nothing
	source = "crossref"
	toFormat::BibliographyFormat = BibtexFormat()
	outputPath = nothing
	mailto = nothing
	plusToken = nothing

	i = 1
	while i ≤ length(args)
		arg = args[i]
		err = ArgumentError("Missing value for $(arg).")
		if arg == "-t" || arg == "--to"
			i += 1
			i > length(args) && throw(err)
			toFormat = parseBibliographyFormat(args[i])
		elseif arg == "--source"
			i += 1
			i > length(args) && throw(err)
			source = lowercase(strip(args[i]))
		elseif arg == "-o" || arg == "--output"
			i += 1
			if i > length(args)
				throw(err)
			end
			outputPath = args[i]
		elseif arg == "-m" || arg == "--mailto"
			i += 1
			if i > length(args)
				throw(err)
			end
			mailto = args[i]
		elseif arg == "--plus-token"
			i += 1
			i > length(args) && throw(err)
			plusToken = args[i]
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in doi mode: $(arg)."))
		else
			if ! isnothing(doi)
				throw(ArgumentError("Unexpected argument in doi mode: $(arg)."))
			end
			doi = arg
		end
		i += 1
	end

	if isnothing(doi)
		throw(ArgumentError("doi: expected a DOI value."))
	end
	if source ∉ doiSources()
		throw(ArgumentError("doi: unknown source '$(source)'. Supported: $(join(doiSources(), ", "))."))
	end

	if isnothing(mailto)
		envMailto = get(ENV, "CROSSREF_MAILTO", "")
		if ! isempty(strip(envMailto))
			mailto = strip(envMailto)
		end
	end
	if isnothing(plusToken)
		envToken = get(ENV, "CROSSREF_PLUS_API_TOKEN", "")
		if ! isempty(strip(envToken))
			plusToken = strip(envToken)
		end
	end

	if source == "crossref" && isnothing(mailto)
		@warn "Crossref polite access recommends a contact email."
		@warn "set --mailto <email> (or CROSSREF_MAILTO). Continuing without it."
	end

	entry = fetchFromDoiSource(doi; source = source, mailto = mailto, plusToken = plusToken)
	text = renderDoiEntry(entry, toFormat)

	if isnothing(outputPath)
		print(output, text)
	else
		write(outputPath, text)
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runQueryCLI(args::Vector{String}; output::IO = stdout)

Handle `--query` mode:
- `--query <bibkey> --library <file>`

Loads the library, looks up `bibkey`, and prints a compact human-readable summary.
If the key is absent, emit a warning and return without throwing.
"""
function runQueryCLI(args::Vector{String}; output::IO = stdout)
	queryKey = nothing
	libraryPath = nothing

	i = 1
	while i ≤ length(args)
		arg = args[i]
		err = ArgumentError("Missing value for $(arg).")
		if arg == "-l" || arg == "--library"
			i += 1
			i > length(args) && throw(err)
			libraryPath = args[i]
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in query mode: $(arg)."))
		else
			if ! isnothing(queryKey)
				throw(ArgumentError("Unexpected argument in query mode: $(arg)."))
			end
			queryKey = strip(arg)
		end
		i += 1
	end

	if isnothing(queryKey)
		throw(ArgumentError("query: expected a bibkey after --query"))
	end
	if isnothing(libraryPath)
		throw(ArgumentError("query: missing --library <file>"))
	end
	if ! isfile(libraryPath)
		throw(ArgumentError("query: library file not found: $(libraryPath)"))
	end

	lib = loadLibrary(libraryPath)
	entry = findByKey(lib, queryKey)
	if isnothing(entry)
		@warn "query: bibkey not found in library" bibkey = queryKey library = libraryPath
		return nothing
	end

	print(output, renderQueriedEntry(entry))
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runBblCLI(args::Vector{String}; output::IO = stdout)

Handle `bbl` mode:
- `bbl <bblfile> <input.bib> <output.bib>`

Read the cited keys from the `.bbl` file, extract the matching entries from the input
library, and write a new file containing only the used keys.
Prints a warning for any keys present in the `.bbl` but missing from the library.
"""
function runBblCLI(args::Vector{String}; output::IO = stdout)
	positional = String[]
	for arg ∈ args
		if startswith(arg, "-")
			throw(ArgumentError("Unknown option in bbl mode: $(arg)."))
		end
		push!(positional, arg)
	end

	if length(positional) ≠ 3
		throw(ArgumentError("bbl: expected <bblfile> <input.bib> <output.bib>"))
	end
	bblPath, inputLibrary, outputPath = positional

	if ! isfile(bblPath)
		throw(ArgumentError("bbl: .bbl file not found: $(bblPath)"))
	end
	if ! isfile(inputLibrary)
		throw(ArgumentError("bbl: input library not found: $(inputLibrary)"))
	end

	result = writeBibFromBbl(bblPath, inputLibrary, outputPath)

	println(output, "Extracted $(length(result.present)) entries to $(outputPath).")
	if ! isempty(result.absent)
		println(output, "Warning: missing keys: ", join(result.absent, ", "))
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runConvertCLI(args::Vector{String})

Handle the `convert` subcommand arguments and perform bibliography conversion.
Expect: `<input> <output>` plus `--to <fmt>` and optional `--from <fmt>`.
Throws ArgumentError for malformed or missing options.
"""
function runConvertCLI(args::Vector{String})
	if length(args) < 2
		throw(ArgumentError("convert: expected <input> <output> --to <fmt> [--from <fmt>]"))
	end
	inputPath  = args[1]
	outputPath = args[2]
	fromFormat = nothing
	toFormat   = nothing

	i = 3
	while i ≤ length(args)
		arg = args[i]
		err = ArgumentError("Missing value for $(arg).")
		if arg == "-f" || arg == "--from"
			i += 1
			if i > length(args)
				throw(err)
			end
			fromFormat = parseBibliographyFormat(args[i])
		elseif arg == "-t" || arg == "--to"
			i += 1
			if i > length(args)
				throw(err)
			end
			toFormat = parseBibliographyFormat(args[i])
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in convert mode: $(arg)."))
		else
			throw(ArgumentError("Unexpected argument in convert mode: $(arg)."))
		end
		i += 1
	end

	if isnothing(toFormat)
		throw(ArgumentError("convert: missing --to <fmt>"))
	end
	if isnothing(fromFormat)
		fromFormat = bibliographyFormat(inputPath)
	end
	convertBibliography(inputPath, outputPath, fromFormat, toFormat)

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runPasteCLI(args; input, output)

Run the `paste` subcommand: read a BibTeX entry from `input` (stdin). 
Optionally print it in the requested format to `output`, and optionally add it to a library.
At least one of `--to` or `--library` must be given.
"""
function runPasteCLI(args::Vector{String}; input::IO = stdin, output::IO = stdout)
	toFormat    = nothing
	libraryPath = nothing

	i = 1
	while i ≤ length(args)
		arg = args[i]
		err = ArgumentError("Missing value for $(arg).")
		if arg == "-t" || arg == "--to"
			i += 1
			i > length(args) && throw(err)
			toFormat = parseBibliographyFormat(args[i])
		elseif arg == "-l" || arg == "--library"
			i += 1
			if i > length(args) 
				throw(err)
			end
			libraryPath = args[i]
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in paste mode: $(arg)."))
		else
			throw(ArgumentError("Unexpected argument in paste mode: $(arg)."))
		end
		i += 1
	end

	if isnothing(toFormat) && isnothing(libraryPath)
		throw(ArgumentError("paste: provide --to <fmt> and/or --library <file>"))
	end

	bibtexText = read(input, String)
	if isempty(strip(bibtexText))
		throw(ArgumentError("paste: no BibTeX entry on stdin"))
	end

	incoming = mktempdir() do dir
		path = joinpath(dir, "pasted.bib")
		write(path, bibtexText)
		return readBibtexLibrary(path)
	end

	if ! isnothing(toFormat)
		print(output, renderPastedEntry(incoming, toFormat))
	end

	if ! isnothing(libraryPath)
		addEntriesToLibrary(incoming, libraryPath)
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runLibUpdateCLI(args; input, output)

Handle `libupdate` mode.
It reads one BibTeX entry from `input` and generate/adjust the key (`surnameYYYYx` or collaboration-based token).
A back up `.bib` library with a timestamp suffix is created to preserve the pre-update state.

- insert/update the entry and save sorted.
"""
function runLibUpdateCLI(args::Vector{String}; input::IO = stdin, output::IO = stdout)
	libraryPath = nothing
	keyOverride = nothing
	fileDir = nothing

	i = 1
	while i ≤ length(args)
		arg = args[i]
		err = ArgumentError("Missing value for $(arg).")
		if arg == "-l" || arg == "--library"
			i += 1
			i > length(args) && throw(err)
			libraryPath = args[i]
		elseif arg == "--key"
			i += 1
			i > length(args) && throw(err)
			keyOverride = strip(args[i])
		elseif arg == "--fileDir"
			i += 1
			i > length(args) && throw(err)
			fileDir = strip(args[i])
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in libupdate mode: $(arg)"))
		else
			throw(ArgumentError("Unexpected argument in libupdate mode: $(arg)"))
		end
		i += 1
	end

	if isnothing(libraryPath)
		throw(ArgumentError("libupdate: missing --library <file>"))
	end
	if ! isfile(libraryPath)
		throw(ArgumentError("libupdate: library file not found: $(libraryPath)"))
	end

	if input isa Base.TTY
		println(output, "Paste one BibTeX entry, then end input with Ctrl-D.")
	end

	bibtexText = read(input, String)
	if isempty(strip(bibtexText))
		throw(ArgumentError("libupdate: no BibTeX entry provided on stdin"))
	end

	incoming = mktempdir() do dir
		pastedPath = joinpath(dir, "pasted.bib")
		write(pastedPath, bibtexText)
		return readBibtexLibrary(pastedPath)
	end
	if length(incoming) ≠ 1
		throw(ArgumentError("libupdate: expected exactly one pasted BibTeX entry."))
	end
		entry = first(values(incoming))

		lib = loadLibrary(libraryPath)
	existing = Set(String.(collect(keys(lib.entries))))

	fileKey = keyFromFileField(entry.fields)

	collabToken, collabName = collaborationTokenForGeneratedKey(entry.fields)
	useCollaboration = ! isnothing(collabToken) && shouldUseCollaborationForGeneratedKey(entry.fields)
	if ! isnothing(collabToken) && ! useCollaboration
		@warn "Detected `onbehalf=true`. Author surname takes precedence over collaboration token: $(collabName)."
	end
	baseToken = useCollaboration ? collabToken : authorTokenForGeneratedKey(entry.fields)
	yearToken = yearTokenForGeneratedKey(entry.fields)
	suggestedKey = nextAvailableGeneratedKey(baseToken, yearToken, existing)

	currentKey = entry.key
	currentPatternOk = validGeneratedKeyPattern(currentKey)
	currentExists = currentKey ∈ existing

	finalKey = suggestedKey
	allowExistingKey = false
	if ! isnothing(keyOverride)
		if ! validGeneratedKeyPattern(keyOverride)
			throw(ArgumentError("libupdate: invalid --key value '$(keyOverride)'; expected lowercase(authorSurname)YearX"))
		end
		if keyOverride ∈ existing
			throw(ArgumentError("libupdate: key '$(keyOverride)' already exists in library"))
		end
		finalKey = keyOverride
	elseif ! isnothing(fileKey)
		if validGeneratedKeyPattern(fileKey)
			finalKey = fileKey
			allowExistingKey = true
		else
			@warn "File field key does not match expected pattern $(fileKey)." 
			if acceptFileKeyFromTty(fileKey; output = output)
				finalKey = fileKey
				allowExistingKey = true
			end
		end
	elseif useCollaboration
		@warn string(
			"`collaboration`` field detected; using collaboration token for key generation:\n", 
			". collaboration = $(collabName)\n",
			". suggested_key = $(suggestedKey)"
		)
		println(output, "Current key:   $(currentKey)")
		println(output, "Suggested key: $(suggestedKey)")
		println(output, "")
		finalKey = chooseKeyFromTty(suggestedKey, existing; output = output)
	elseif currentKey ≠ suggestedKey || ! currentPatternOk || currentExists
		println(output, "Using key '$(suggestedKey)' (original key was '$(currentKey)').")
	end

	candidateEntry = ZettelEntry(finalKey, entry.entryType, entry.fields)
	similarEntry = findVerySimilarEntry(lib, candidateEntry)
	if ! isnothing(similarEntry)
		@warn "similar entry detected; skipping insert" existingKey = similarEntry.existingKey matchedFieldNames = similarEntry.matchedFieldNames textRatio = similarEntry.textRatio authorScore = similarEntry.authorScore totalScore = similarEntry.totalScore totalThreshold = similarEntry.totalThreshold year = similarEntry.year volume = similarEntry.volume
		return nothing
	end

	if finalKey ∈ existing && ! allowExistingKey
		throw(ArgumentError("libupdate: chosen key '$(finalKey)' already exists in library."))
	end
	if finalKey ∈ existing && allowExistingKey
		@warn "Chosen key already exists in library; existing entry will be overwritten: $(finalKey)."
	end

	matches = matchingKeyFiles(finalKey, libraryPath; fileDir = fileDir)
	if ! isempty(matches)
		@warn "file(s) found matching key" key = finalKey files = matches
	end

	updated = ZettelEntry(finalKey, entry.entryType, entry.fields)
	timestamp = Libc.strftime("%Y%m%d-%H%M%S", time())
	backupPath = "$(libraryPath).$(timestamp).bak"
	cp(libraryPath, backupPath; force = true)

	push!(lib, updated)
	saveLibrary(sort(lib), libraryPath)

	println(output, "Backup created: $(backupPath)")
	println(output, "Library updated: $(libraryPath)")
	println(output, "Inserted key:    $(finalKey)")

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runAuxCLI(args::Vector{String}; output::IO = stdout)

Handle the auxiliary-file (`.aux`) mode. 
Parse options for library files, output `.bbl` path, and bibliography style. 
Then generate the `.bbl` using the provided libraries (or inferred ones). 
Prints a warning to `output` if any citation keys are missing.
"""
function runAuxCLI(args::Vector{String}; output::IO = stdout)
	auxPath   = nothing
	libraries = String[]
	outputPath = nothing
	style     = "auto"

	i = 1
	while i ≤ length(args)
		arg = args[i]
		err = ArgumentError("Missing value for $(arg).")
		if arg == "-l" || arg == "--library"
			i += 1
			i > length(args) && throw(err)
			push!(libraries, args[i])
		elseif arg == "-o" || arg == "--output"
			i += 1
			i > length(args) && throw(err)
			outputPath = args[i]
		elseif arg == "-s" || arg == "--style"
			i += 1
			i > length(args) && throw(err)
			style = args[i]
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option: $(arg)"))
		else
			if ! isnothing(auxPath)
				throw(ArgumentError("Unexpected argument: $(arg)"))
			end
			auxPath = arg
		end
		i += 1
	end

	if isnothing(auxPath)
		throw(ArgumentError("No aux file provided."))
	end

	libFiles = isempty(libraries) ? nothing : libraries
	result = writeBblFromAux(auxPath; libraryFiles = libFiles, outputPath = outputPath, style = style)

	if ! isempty(result.absent)
		println(output, "Warning: missing keys: ", join(result.absent, ", "))
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	isPossibleDoiInvocation(args)

Return `true` when CLI args appear to be the DOI shorthand form:
`zettel <doi> [--source ... --to ...]`.
"""
function isPossibleDoiInvocation(args::Vector{String})
	if isempty(args)
		return false
	end
	token = strip(args[1])
	return startswith(token, "10.") && occursin("/", token)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderDoiEntry(entry::ZettelEntry, format::BibliographyFormat)

Render a DOI-fetched entry in the same external representation style used by `entryToString`.
"""
function renderDoiEntry(entry::ZettelEntry, format::BibliographyFormat)
	text = entryToString(entry, format)
	if ! endswith(text, "\n")
		text *= "\n"
	end
	return text
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderQueriedEntry(entry::ZettelEntry)

Render one entry in compact human-readable form:
```
"The title"
F. Author, S. Author, ...
Journal year, volume number
arXiv:XXXXXXXX
doi: XXXXXXX
bibkey: author20XXa
```
"""
function renderQueriedEntry(entry::ZettelEntry)
	lines = String[]

	title = _queryFieldText(getTitle(entry))
	if ! isempty(title)
		push!(lines, "\"$(title)\"")
	end

	authorsLine = renderQueryAuthors(entry)
	if ! isempty(authorsLine)
		push!(lines, authorsLine)
	end

	journalLine = renderQueryVenue(entry)
	if ! isempty(journalLine)
		push!(lines, journalLine)
	end

	arxivId = queryArxivId(entry)
	if ! isempty(arxivId)
		push!(lines, "arXiv:$(arxivId)")
	end

	doi = _queryFieldText(getDOI(entry))
	if ! isempty(doi)
		push!(lines, "doi: $(doi)")
	end

	push!(lines, "bibkey: $(entry.key)")

	return join(lines, "\n") * "\n"
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderQueryAuthors(entry::ZettelEntry)

Render the author/collaboration line for query output.
"""
function renderQueryAuthors(entry::ZettelEntry)
	fields = entry.fields
	collaboration = _queryFieldText(get(fields, "collaboration", ""))
	onbehalf = _fieldIsTrue(get(fields, "onbehalf", ""))

	if ! isempty(collaboration)
		if onbehalf
			author = _queryFirstAuthor(entry)
			if isempty(author)
				return "et al. for $(collaboration)"
			end
			return "$(author) et al. for $(collaboration)"
		end
		return collaboration
	end

	authors = splitBibtexNames(getAuthors(entry))
	formatted = String[]
	for rawAuthor ∈ authors
		author = _queryPersonSummary(rawAuthor)
		if ! isempty(author)
			push!(formatted, author)
		end
	end

	return join(formatted, ", ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderQueryVenue(entry::ZettelEntry)

Render the journal/year/volume/number line for query output.
"""
function renderQueryVenue(entry::ZettelEntry)
	journal = _queryFieldText(getJournal(entry))
	year = _queryFieldText(getYear(entry))
	volume = _queryFieldText(getVolume(entry))
	number = _queryFieldText(getNumber(entry))

	parts = String[]
	if ! isempty(journal)
		push!(parts, journal)
	end
	if ! isempty(year)
		push!(parts, year)
	end
	if ! isempty(volume)
		push!(parts, volume)
	end
	if ! isempty(number)
		push!(parts, number)
	end

	return join(parts, ", ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	queryArxivId(entry::ZettelEntry)

Extract an arXiv identifier from `eprint`/`archivePrefix` fields.
"""
function queryArxivId(entry::ZettelEntry)
	eprint = _queryFieldText(getField(entry, "eprint"))
	if isempty(eprint)
		return ""
	end

	arxiv = replace(eprint, r"^arxiv:\s*"i => "")
	arxiv = strip(arxiv)
	prefix = lowercase(_queryFieldText(getField(entry, "archivePrefix")))
	if isempty(prefix) || prefix == "arxiv"
		return arxiv
	end

	return ""
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_queryFirstAuthor(entry::ZettelEntry)

Return the first author as `F. Surname`.
"""
function _queryFirstAuthor(entry::ZettelEntry)
	authors = splitBibtexNames(getAuthors(entry))
	if isempty(authors)
		return ""
	end
	return _queryPersonSummary(first(authors))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_queryPersonSummary(rawName)

Convert one BibTeX person name to `F. Surname` format.
"""
function _queryPersonSummary(rawName::AbstractString)
	person = parseBibtexPerson(rawName)
	lastName = _queryFieldText(person.lastName)
	if isempty(lastName)
		lastName = _queryFieldText(rawName)
	end

	initials = String[]
	for token ∈ split(strip(person.firstName), r"\s+")
		t = strip(token)
		isempty(t) && continue
		push!(initials, string(uppercase(first(t)), "."))
	end
	for token ∈ split(strip(person.middleName), r"\s+")
		t = strip(token)
		isempty(t) && continue
		push!(initials, string(uppercase(first(t)), "."))
	end

	if isempty(initials)
		return lastName
	end
	if isempty(lastName)
		return join(initials, " ")
	end
	return "$(join(initials, " ")) $(lastName)"
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_queryFieldText(text)

Normalise one field for query-mode plain-text printing.
"""
function _queryFieldText(text::AbstractString)
	return strip(decodeTex(stripOuterBraces(text)))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	addEntriesToLibrary(incoming::ZettelLibrary, libraryPath::AbstractString)

Add entries from `incoming` into the library file at `libraryPath`, creating the library if it does not exist. 
The resulting library is sorted and written back to disc.
"""
function addEntriesToLibrary(incoming::ZettelLibrary, libraryPath::AbstractString)
	lib = isfile(libraryPath) ? loadLibrary(libraryPath) : ZettelLibrary()
	for entry ∈ values(incoming)
		push!(lib, entry)
	end

	saveLibrary(sort(lib), libraryPath)
	
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	chooseKeyFromTty(suggested, existing; output)

Interactively choose a citation key from the terminal.
If no interactive terminal is detected, return the suggested key.
Otherwise, prompt the user to accept the suggested key or enter a custom key.
Validate the custom key against the expected pattern and check for conflicts with existing keys.
Return the final chosen key.

# Input
- `suggested::AbstractString`: the suggested citation key to accept or override.
- `existing::Set{String}`: set of existing keys in the library to check for conflicts.
- `output::IO`: the IO stream to use for prompts and messages (default: stdout).

# Output
- The chosen citation key as a string.
"""
function chooseKeyFromTty(suggested::AbstractString, existing::Set{String}; output::IO = stdout)
	if ! (stdin isa Base.TTY) || ! ispath("/dev/tty")
		println(output, "No interactive terminal detected; accepting suggested key '$(suggested)'.")
		return String(suggested)
	end

	open("/dev/tty", "r+") do tty
		println(tty, "Press Enter to accept the suggested key, or type a custom key.")
		while true
			print(tty, "Key [", suggested, "]: ")
			flush(tty)

			reply = try
				readline(tty)
			catch
				""
			end

			key = strip(reply)
			if isempty(key)
				return String(suggested)
			end
			if ! validGeneratedKeyPattern(key)
				println(tty, "Invalid key format. Expected lowercase(authorSurname)YearX, e.g. einstein1905a.")
				continue
			end

			if key ∈ existing
				println(tty, "Key '", key, "' already exists in the library.")
				continue
			end

			return key
		end
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	acceptFileKeyFromTty(fileKey; output)

Prompt on TTY to accept/reject a file-derived key that does not match the expected pattern.
Returns `true` when accepted, `false` otherwise.
"""
function acceptFileKeyFromTty(fileKey::AbstractString; output::IO = stdout)
	if ! (stdin isa Base.TTY) || ! ispath("/dev/tty")
		println(output, "No interactive terminal detected; rejecting key inferred from file: '$(fileKey)'.")
		return false
	end

	open("/dev/tty", "r+") do tty
		while true
			print(tty, "Use file-derived key '", fileKey, "' anyway? [y/N]: ")
			flush(tty)

			reply = try
				readline(tty)
			catch
				""
			end
			answer = lowercase(strip(reply))
			if isempty(answer) || answer ∈ ("n", "no")
				return false
			elseif answer ∈ ("y", "yes")
				return true
			end
		end
	end
end

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderPastedEntry(lib::ZettelLibrary, format::BibliographyFormat)
	renderPastedEntry(lib::ZettelLibrary, ::Type{<: BibliographyFormat})

Render pasted BibTeX entries as BibTeX / JSON / YAML.
"""
function renderPastedEntry(lib::ZettelLibrary, ::Type{BibtexFormat})
	io  = IOBuffer()
	for entry ∈ values(lib)
		println(io, entryToString(entry, BibtexFormat()))
		println(io)
	end
	return String(take!(io))
end

function renderPastedEntry(lib::ZettelLibrary, ::Type{JsonFormat})
	data = if length(lib) == 1
		entryToStructuredDict(first(values(lib)))
	else
		[entryToStructuredDict(entry) for entry ∈ values(lib)]
	end

	io = IOBuffer()
	JSON3.pretty(io, data, JSON3.AlignmentContext(; indent = 4))
	text = String(take!(io))
	if ! endswith(text, "\n")
		text *= "\n"
	end

	return text
end

function renderPastedEntry(lib::ZettelLibrary, ::Type{YamlFormat})
	data = if length(lib) == 1
		entryToStructuredDict(first(values(lib)))
	else
		[entryToStructuredDict(entry) for entry ∈ values(lib)]
	end
	
	text = YAML.write(normaliseYaml(data))
	if ! endswith(text, "\n")
		text *= "\n"
	end

	return text
end

function renderPastedEntry(lib::ZettelLibrary, format::BibliographyFormat) 
	return renderPastedEntry(lib, typeof(format))
end




# ----------------------------------------------------------------------------------------------- #
