# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runDoiCLI(args::Vector{String}; output::IO = stdout)

Handle the `doi` subcommand and fetch one entry from a DOI metadata source.
Expected form:
	`doi <doi> [--source <name>] [--to <fmt>] [--output <file>] [--mailto <email>] [--plus-token <token>]`
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

	entry = findEntryByKey(libraryPath, queryKey)
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

Read the cited keys from the `.bbl` file, extract the matching entries from the input [`ZettelLibrary`](@ref), and write a new file containing only the used keys.
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
	runConvertCLI(args::Vector{String}; output::IO = stdout)

Handle the `convert` subcommand arguments and perform bibliography conversion.
Expect: `<input> <output>` plus `--to <fmt>` and optional `--from <fmt>`.
Throws ArgumentError for malformed or missing options.
"""
function runConvertCLI(args::Vector{String}; output::IO = stdout)
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
	println(output, "Converting $(inputPath) -> $(outputPath)")
	convertBibliography(inputPath, outputPath, fromFormat, toFormat)
	println(output, "Wrote $(outputPath)")

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	runPasteCLI(args; input, output)

Run the `paste` subcommand: read a BibTeX entry from `input` (stdin).
Optionally print it in the requested format to `output`, and optionally add it to a library.
When `--library` is present, the inserted entry receives a generated key based on the first author or collaboration and publication year.
When `--library` points at a `.json`/`.yaml` file, the pasted BibTeX entry is converted to that library's format before it is inserted (BibTeX TeX escapes become UTF-8).
At least one of `--to` or `--library` must be given.
"""
function runPasteCLI(args::Vector{String}; input::IO = stdin, output::IO = stdout)
	toFormat = nothing
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

	rendered = incoming
	if ! isnothing(libraryPath)
		rendered = addEntriesToLibrary(incoming, libraryPath)
	end

	if ! isnothing(toFormat)
		print(output, renderPastedEntry(rendered, toFormat))
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
	saveLibrary(sort!(lib), libraryPath)

	println(output, "Backup created:  $(backupPath)")
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
	auxPath = nothing
	libraries = String[]
	outputPath = nothing
	style = "auto"

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
	println(output, "Wrote $(result.outputPath) with $(length(result.usedKeys)) entries.")

	if ! isempty(result.absent)
		println(output, "Warning: missing keys: ", join(result.absent, ", "))
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
