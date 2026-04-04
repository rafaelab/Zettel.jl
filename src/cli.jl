# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_cliUsage(; io::IO = stdout)

Print the command-line usage/help text to `io` (defaults to stdout). 
Used by the CLI when `-h`/`--help` is requested or when no arguments are provided.
"""
function _cliUsage(; io::IO = stdout)
	println(io, "Usage:")
	println(io, "  zettel convert <input> <output> [--from <fmt>] --to <fmt>")
	println(io, "  zettel doi     <doi> [--source <name>] [--to <fmt>] [--output <file>] [--mailto <email>] [--plus-token <token>]")
	println(io, "  zettel paste   [--to <fmt>] --library <file>")
	println(io, "  zettel paste   --to <fmt>")
	println(io, "  zettel <auxfile> [options]")
	println(io, "")
	println(io, "Commands:")
	println(io, "  convert        Convert a bibliography file between formats (bib, json, yaml).")
	println(io, "  doi            Fetch a DOI from a metadata source and emit one ZettelEntry (bib, json, yaml).")
	println(io, "  paste          Read a BibTeX entry from stdin; print it and/or add it to a library.")
	println(io, "")
	println(io, "Options (convert):")
	println(io, "  -f, --from <fmt>       Input format (inferred from extension when omitted)")
	println(io, "  -t, --to   <fmt>       Output format (required)")
	println(io, "")
	println(io, "Options (doi):")
	println(io, "      --source <name>    Metadata source (default: crossref; supported: $(join(doiSources(), ", ")))")
	println(io, "  -t, --to <fmt>         Output format for the fetched entry (bib, json, yaml; default: bib)")
	println(io, "  -o, --output <file>    Write output to file instead of stdout")
	println(io, "  -m, --mailto <email>   Contact email for Crossref polite access (crossref source)")
	println(io, "      --plus-token <tok> Crossref Metadata Plus API token (crossref source, optional)")
	println(io, "")
	println(io, "Options (paste):")
	println(io, "  -t, --to   <fmt>       Print the entry in this format to stdout (bib, json, yaml)")
	println(io, "  -l, --library <file>   Add the entry to this library and rewrite it")
	println(io, "")
	println(io, "Options (aux mode):")
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

## Commands
- `zettel convert <input> <output> [--from <fmt>] --to <fmt>`: convert between bib/json/yaml.
- `zettel paste [--to <fmt>] [--library <file>]`: read a BibTeX entry from stdin, print it in the requested format and/or add it to a library.
- `zettel <auxfile> [options]`: generate a `.bbl` file from a `.aux` file.
"""
function zettelCLI(; args = ARGS, input::IO = stdin, output::IO = stdout)
	if isempty(args) || ("-h" ∈ args) || ("--help" ∈ args)
		_cliUsage(io = output)
		return 0
	end

	if args[1] == "convert"
		_runConvertCLI(args[2 : end])
		return 0
	end

	if args[1] == "doi"
		_runDoiCLI(args[2 : end]; output = output)
		return 0
	end

	# shorthand DOI mode: zettel <doi> [doi-options]
	if _looksLikeDoiInvocation(args)
		_runDoiCLI(args; output = output)
		return 0
	end

	# shorthand: zettel <input> <output>  (formats inferred from extensions)
	if length(args) == 2 && ! startswith(args[1], "-") && ! startswith(args[2], "-")
		convertBibliography(args[1], args[2], bibliographyFormat(args[1]), bibliographyFormat(args[2]))
		return 0
	end

	if args[1] == "paste"
		_runPasteCLI(args[2 : end]; input = input, output = output)
		return 0
	end

	# aux mode
	_runAuxCLI(args; output = output)
	return 0
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_looksLikeDoiInvocation(args)

Return `true` when CLI args appear to be the DOI shorthand form:
`zettel <doi> [--source ... --to ...]`.
"""
function _looksLikeDoiInvocation(args::Vector{String})
	isempty(args) && return false
	token = strip(args[1])
	return startswith(token, "10.") && occursin("/", token)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_runDoiCLI(args::Vector{String}; output::IO = stdout)

Handle the `doi` subcommand and fetch one entry from a DOI metadata source.

Expected form:
- `doi <doi> [--source <name>] [--to <fmt>] [--output <file>] [--mailto <email>] [--plus-token <token>]`

For source `crossref`, polite access requires a contact email via `--mailto` or `CROSSREF_MAILTO`.
"""
function _runDoiCLI(args::Vector{String}; output::IO = stdout)
	doi = nothing
	source = "crossref"
	toFormat::BibliographyFormat = bibTeXFormat()
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
			i > length(args) && throw(err)
			outputPath = args[i]
		elseif arg == "-m" || arg == "--mailto"
			i += 1
			i > length(args) && throw(err)
			mailto = args[i]
		elseif arg == "--plus-token"
			i += 1
			i > length(args) && throw(err)
			plusToken = args[i]
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in doi mode: $(arg)"))
		else
			isnothing(doi) || throw(ArgumentError("Unexpected argument in doi mode: $(arg)"))
			doi = arg
		end
		i += 1
	end

	isnothing(doi) && throw(ArgumentError("doi: expected a DOI value"))
	source ∈ doiSources() || throw(ArgumentError("doi: unknown source '$(source)'. Supported: $(join(doiSources(), ", "))"))

	if isnothing(mailto)
		envMailto = get(ENV, "CROSSREF_MAILTO", "")
		! isempty(strip(envMailto)) && (mailto = strip(envMailto))
	end
	if isnothing(plusToken)
		envToken = get(ENV, "CROSSREF_PLUS_API_TOKEN", "")
		! isempty(strip(envToken)) && (plusToken = strip(envToken))
	end

	if source == "crossref" && isnothing(mailto)
		println(stderr, "Warning: Crossref polite access recommends a contact email.")
		println(stderr, "Warning: set --mailto <email> (or CROSSREF_MAILTO). Continuing without it.")
	end

	entry = fetchFromDoiSource(doi; source = source, mailto = mailto, plusToken = plusToken)
	text = _renderDoiEntry(entry, toFormat)

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
	_runConvertCLI(args::Vector{String})

Handle the `convert` subcommand arguments and perform bibliography conversion.
Expect: `<input> <output>` plus `--to <fmt>` and optional `--from <fmt>`.
Throws ArgumentError for malformed or missing options.
"""
function _runConvertCLI(args::Vector{String})
	length(args) < 2 && throw(ArgumentError("convert: expected <input> <output> --to <fmt> [--from <fmt>]"))
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
			i > length(args) && throw(err)
			fromFormat = parseBibliographyFormat(args[i])
		elseif arg == "-t" || arg == "--to"
			i += 1
			i > length(args) && throw(err)
			toFormat = parseBibliographyFormat(args[i])
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in convert mode: $(arg)"))
		else
			throw(ArgumentError("Unexpected argument in convert mode: $(arg)"))
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
	_runPasteCLI(args; input, output)

Run the `paste` subcommand: read a BibTeX entry from `input` (stdin), optionally print it in the
requested format to `output`, and optionally add it to a library.

At least one of `--to` or `--library` must be given.
"""
function _runPasteCLI(args::Vector{String}; input::IO = stdin, output::IO = stdout)
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
			i > length(args) && throw(err)
			libraryPath = args[i]
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in paste mode: $(arg)"))
		else
			throw(ArgumentError("Unexpected argument in paste mode: $(arg)"))
		end
		i += 1
	end

	isnothing(toFormat) && isnothing(libraryPath) &&
		throw(ArgumentError("paste: provide --to <fmt> and/or --library <file>"))

	bibTeXText = read(input, String)
	isempty(strip(bibTeXText)) && throw(ArgumentError("paste: no BibTeX entry on stdin"))

	# parse to structured per-key dict (Zettel-JSON format)
	data = mktempdir() do dir
		path = joinpath(dir, "pasted.bib")
		write(path, bibTeXText)
		return _bibTeXToStructuredData(path)
	end

	if ! isnothing(toFormat)
		print(output, _renderPastedEntry(data, toFormat))
	end

	if ! isnothing(libraryPath)
		incoming = _libraryFromParsedData(data, "<stdin>", "BibTeX")
		_addEntriesToLibrary(incoming, libraryPath)
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_addEntriesToLibrary(incoming::ZettelLibrary, libraryPath::AbstractString)

Add entries from `incoming` into the library file at `libraryPath`, creating the
library if it does not exist. The resulting library is sorted and written back to disk.
"""
function _addEntriesToLibrary(incoming::ZettelLibrary, libraryPath::AbstractString)
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
	_runAuxCLI(args::Vector{String}; output::IO = stdout)

Handle the auxiliary-file (`.aux`) mode. Parse options for library files, output
`.bbl` path, and bibliography style, then generate the `.bbl` using the provided
libraries (or inferred ones). Prints a warning to `output` if any citation keys are missing.
"""
function _runAuxCLI(args::Vector{String}; output::IO = stdout)
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
			isnothing(auxPath) || throw(ArgumentError("Unexpected argument: $(arg)"))
			auxPath = arg
		end
		i += 1
	end

	isnothing(auxPath) && throw(ArgumentError("No aux file provided."))

	libFiles = isempty(libraries) ? nothing : libraries
	result   = writeBblFromAux(auxPath; libraryFiles = libFiles, outputPath = outputPath, style = style)

	if ! isempty(result.absent)
		println(output, "Warning: missing keys: ", join(result.absent, ", "))
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_renderDoiEntry(entry::ZettelEntry, format::BibliographyFormat)

Render a DOI-fetched entry in the same external representation style used by `paste`.
For JSON/YAML this is the structured per-key format; for BibTeX it is a single BibTeX entry.
"""
function _renderDoiEntry(entry::ZettelEntry, format::BibliographyFormat)
	if format isa BibTeXFormat
		text = entryToString(entry, format)
		endswith(text, "\n") || (text *= "\n")
		return text
	end

	data = _structuredDataFromEntry(entry)
	return _renderPastedEntry(data, format)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_structuredDataFromEntry(entry::ZettelEntry)

Convert one `ZettelEntry` into the structured per-key map used by JSON/YAML CLI output.
"""
function _structuredDataFromEntry(entry::ZettelEntry)
	return mktempdir() do dir
		path = joinpath(dir, "entry.bib")
		text = entryToString(entry, bibTeXFormat())
		endswith(text, "\n") || (text *= "\n")
		write(path, text)
		_bibTeXToStructuredData(path)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_renderPastedEntry(data::AbstractDict, ::JsonFormat)

Render structured pasted entry data as pretty JSON (Zettel-JSON interchange format).
"""
function _renderPastedEntry(data::AbstractDict, ::JsonFormat)
	buf = IOBuffer()
	JSON3.pretty(buf, data, JSON3.AlignmentContext(indent = 4))
	text = String(take!(buf))
	endswith(text, "\n") || (text *= "\n")
	return text
end

@doc """
	_renderPastedEntry(data::AbstractDict, ::YamlFormat)

Render structured pasted entry data as YAML.
"""
function _renderPastedEntry(data::AbstractDict, ::YamlFormat)
	text = YAML.write(_toYamlData(data))
	endswith(text, "\n") || (text *= "\n")
	return text
end

@doc """
	_renderPastedEntry(data::AbstractDict, ::BibTeXFormat)

Render structured pasted entry data back to BibTeX format. Returns the textual
BibTeX entries as they would be written to stdout or a file.
"""
function _renderPastedEntry(data::AbstractDict, ::BibTeXFormat)
	lib = _libraryFromParsedData(data, "<stdin>", "BibTeX")
	io  = IOBuffer()
	for entry ∈ values(lib)
		println(io, entryToString(entry, bibTeXFormat()))
		println(io)
	end
	return String(take!(io))
end


# ----------------------------------------------------------------------------------------------- #
