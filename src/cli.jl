# ----------------------------------------------------------------------------------------------- #
#
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
function _bibTeXTextToStructuredData(bibTeXText::AbstractString)
	return mktempdir() do dir
		inputPath = joinpath(dir, "stdin_input.bib")
		write(inputPath, bibTeXText)
		return _bibTeXToStructuredData(inputPath)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
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
function _sortedLibraryByKey(lib::ZettelLibrary)
	sortedKeys = sort(collect(keys(lib.entries)))
	entries = ZettelEntry[lib.entries[key] for key ∈ sortedKeys]
	return ZettelLibrary(entries)
end


# ----------------------------------------------------------------------------------------------- #
#
function _runConvertCLI(args::Vector{String})
	length(args) < 2 && throw(ArgumentError("convert mode expects: zettel convert <input> <output> --to <type> [--from <type>]"))
	inputPath = args[1]
	outputPath = args[2]
	fromFormat = nothing
	toFormat = nothing

	i = 3
	while i <= length(args)
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