# ----------------------------------------------------------------------------------------------- #
#
@doc """
	zettelCLI(; args = ARGS)

Command-line entry point for `zettel`. Parses command-line arguments and dispatches to the appropriate functionality.

# Usage
- `zettel <auxfile> [options]`: Generate a .bbl file from a .aux file, optionally using specified libraries and style.
- `zettel <input.bib> <output.json>`: Convert a BibTeX file to JSON format.
- `zettel convert <input> <output> --to <json|yaml|bib> [--from <json|yaml|bib>]`: Convert a bibliography file between supported formats, with optional format inference.
- `zettel paste --to <json|yaml> [--library <file>]`: Read a BibTeX entry from stdin and output it in the specified format, optionally adding it to a library.

# Input
- Command-line arguments as described above.

# Output
- Depends on the command used. Can be a .bbl file, a converted bibliography file, or a formatted bibliography entry printed to stdout.
"""
function _cliUsage(; io::IO = stdout)
	println(io, "Usage: zettel <auxfile> [options]")
	println(io, "       zettel <input.bib> <output.json>")
	println(io, "       zettel convert <input> <output> --to <json|yaml|bib> [--from <json|yaml|bib>]")
	println(io, "       zettel paste --to <json|yaml> [--library <file>]")
	println(io, "")
	println(io, "Options:")
	println(io, "  -l, --library <file>   Path to a .json, .yaml/.yml, or .bib library (repeatable)")
	println(io, "  -o, --output <file>    Output .bbl path (default: <auxfile>.bbl)")
	println(io, "  -s, --style <name>     Bibliography style (default: auto -> \\bibstyle{...} or plain)")
	println(io, "  -f, --from <type>      Input type for convert mode (optional: infer from extension)")
	println(io, "  -t, --to <type>        Output type for convert mode (mandatory in convert mode)")
	println(io, "  -h, --help             Show this help message")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	zettelCLI(; args = ARGS)

Command-line entry point for `zettel`.

# Usage
- `zettel <auxfile> [options]`: Generate a .bbl file from a .aux file, optionally using specified libraries and style.
- `zettel <input.bib> <output.json>`: Convert a BibTeX file to JSON format.
- `zettel convert <input> <output> --to <json|yaml|bib> [--from <json|yaml|bib>]`: Convert a bibliography file between supported formats, with optional format inference.

# Input
- Command-line arguments as described above.

# Output
- Depends on the command used. Can be a .bbl file, a converted bibliography file, or a formatted bibliography entry printed to stdout.
"""
function zettelCLI(; args = ARGS, input::IO = stdin, output::IO = stdout)
	if isempty(args) || ("-h" ∈ args) || ("--help" ∈ args)
		_cliUsage(io = output)
		return 0
	end

	if length(args) == 2 && ! startswith(args[1], "-") && !startswith(args[2], "-") &&
		endswith(lowercase(args[1]), ".bib") && endswith(lowercase(args[2]), ".json")
		convertBibliography(args[1], args[2], bibTeXFormat(), jsonFormat())
		return 0
	end

	if args[1] == "convert"
		_runConvertCLI(args[2 : end])
		return 0
	end

	if args[1] == "paste"
		_runPasteCLI(args[2 : end]; input = input, output = output)
		return 0
	end

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
			if isnothing(auxPath)
				auxPath = arg
			else
				throw(ArgumentError("Unexpected argument: $(arg)"))
			end
		end
		i += 1
	end

	if isnothing(auxPath)
		throw(ArgumentError("No aux file provided."))
	end

	libFile = isempty(libraries) ? nothing : libraries
	result = writeBblFromAux(auxPath; libraryFiles = libFile, outputPath = outputPath, style = style)

	absent = hasproperty(result, :absent) ? result.absent : String[]

	if ! isempty(absent)
		println(stderr, "Warning: absent entries for keys: ", join(absent, ", "))
	end

	return 0
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_runPasteCLI(args; input, output)

Run the "paste" subcommand of the CLI, which reads a BibTeX entry from stdin and outputs it in the specified format, optionally adding it to a library.	

# Input
- `args::Vector{String}`: command-line arguments for the paste subcommand.
- `input::IO`: input stream to read the BibTeX entry from (default: `stdin`).
- `output::IO`: output stream to write the formatted entry to (default: `stdout`).

# Output
- `nothing`. The formatted entry is written to `output`, and optionally added to a library if `--library` is specified.
"""
function _runPasteCLI(args::Vector{String}; input::IO = stdin, output::IO = stdout)
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
			i > length(args) && throw(err)
			libraryPath = args[i]
		elseif startswith(arg, "-")
			throw(ArgumentError("Unknown option in paste mode: $(arg)"))
		else
			throw(ArgumentError("Unexpected argument in paste mode: $(arg)"))
		end
		i += 1
	end

	if isnothing(toFormat)
		throw(ArgumentError("Missing required output type. Use --to <json|yaml>."))
	end

	if toFormat isa BibTeXFormat
		throw(ArgumentError("Paste mode only supports --to json or --to yaml."))
	end

	bibTeXText = read(input, String)
	if isempty(strip(bibTeXText))
		throw(ArgumentError("No BibTeX entry received on stdin."))
	end

	data = _bibTeXTextToStructuredData(bibTeXText)
	rendered = _renderStructuredData(data, toFormat)
	print(output, rendered)

	if ! isnothing(libraryPath)
		_addStructuredDataToLibrary(data, libraryPath, toFormat)
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	zettelCLI(; args = ARGS)

Command-line entry point for `zettel`. Parses command-line arguments and dispatches to the appropriate functionality.

# Usage
- `zettel <auxfile> [options]`: Generate a .bbl file from a .aux file, optionally using specified libraries and style.
- `zettel <input.bib> <output.json>`: Convert a BibTeX file to JSON format.
- `zettel convert <input> <output> --to <json|yaml|bib> [--from <json|yaml|bib>]`: Convert a bibliography file between supported formats, with optional format inference.

# Input
- Command-line arguments as described above.

# Output
- Depends on the command used. Can be a .bbl file, a converted bibliography file, or a formatted bibliography entry printed to stdout.
"""
function _bibTeXTextToStructuredData(bibTeXText::AbstractString)
	return mktempdir() do dir
		inputPath = joinpath(dir, "stdin_input.bib")
		write(inputPath, bibTeXText)
		return _bibTeXToStructuredData(inputPath)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_renderStructuredData(data, format)

Render structured bibliography data into a string in the specified format.

# Input
- `data::AbstractDict`: structured bibliography data (e.g., parsed from a BibTeX entry).
- `format::BibliographyFormat`: format selector for the output string.

# Output
- A string representation of `data` in the specified format.
"""
function _renderStructuredData(data::AbstractDict, ::JsonFormat)
	buf = IOBuffer()
	JSON3.pretty(buf, data, JSON3.AlignmentContext(indent = 4))
	text = String(take!(buf))
	if ! isempty(text) && text[end] != '\n'
		text *= "\n"
	end
	return text
end


function _renderStructuredData(data::AbstractDict, ::YamlFormat)
	text = YAML.write(_toYamlData(data))
	if ! isempty(text) && text[end] != '\n'
		text *= "\n"
	end
	return text
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_addStructuredDataToLibrary(data, libraryPath, toFormat)

Add structured bibliography data to an existing library file, creating the library if it does not exist.

# Input
- `data::AbstractDict`: structured bibliography data (e.g., parsed from a BibTeX entry).
- `libraryPath::AbstractString`: path to the library file.
- `toFormat::BibliographyFormat`: format selector for the output string.

# Output
- Nothing. The library file is updated in place.
"""
function _addStructuredDataToLibrary(data::AbstractDict, libraryPath::AbstractString, toFormat::BibliographyFormat)
	libraryFormat = bibliographyFormat(libraryPath)
	typeof(libraryFormat) == typeof(toFormat) || throw(ArgumentError("Library format must match --to output format."))

	lib = isfile(libraryPath) ? readBibliography(libraryFormat, libraryPath) : ZettelLibrary()
	incoming = _libraryFromParsedData(data, "<stdin>", "BibTeX")

	for entry ∈ values(incoming.entries)
		push!(lib, entry)
	end

	writeBibliography(libraryFormat, _sortedLibraryByKey(lib), libraryPath)

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_sortedLibraryByKey(lib)

Return a new `ZettelLibrary` with entries sorted by their keys.

# Input
- `lib::ZettelLibrary`: the library to be sorted.

# Output
- A new `ZettelLibrary` with entries sorted by their keys.
"""
function _sortedLibraryByKey(lib::ZettelLibrary)
	sortedKeys = sort(collect(keys(lib.entries)))
	entries = ZettelEntry[lib.entries[key] for key ∈ sortedKeys]
	return ZettelLibrary(entries)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_runConvertCLI(args)

Run the "convert" subcommand of the CLI, which converts a bibliography file between supported formats.

# Input
- `args::Vector{String}`: command-line arguments for the convert subcommand.

# Output
- Nothing. The converted file is written to the specified output path.
"""
function _runConvertCLI(args::Vector{String})
	length(args) < 2 && throw(ArgumentError("convert mode expects: zettel convert <input> <output> --to <type> [--from <type>]"))
	inputPath = args[1]
	outputPath = args[2]
	fromFormat = nothing
	toFormat = nothing

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
		throw(ArgumentError("Missing required output type. Use --to <json|yaml|bib>."))
	end

	if isnothing(fromFormat)
		fromFormat = bibliographyFormat(inputPath)
	end

	convertBibliography(inputPath, outputPath, fromFormat, toFormat)

	return nothing
end

# ----------------------------------------------------------------------------------------------- #