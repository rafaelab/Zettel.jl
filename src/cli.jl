# ----------------------------------------------------------------------------------------------- #
#
function _cliUsage(; io::IO = stdout)
	println(io, "Usage: zettel <auxfile> [options]")
	println(io, "       zettel <input.bib> <output.json>")
	println(io, "       zettel convert <input> <output> --to <json|yaml|bib> [--from <json|yaml|bib>]")
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
function zettelCLI(; args = ARGS)
	if isempty(args) || ("-h" ∈ args) || ("--help" ∈ args)
		_cliUsage()
		return 0
	end

	if length(args) == 2 && !startswith(args[1], "-") && !startswith(args[2], "-") &&
		endswith(lowercase(args[1]), ".bib") && endswith(lowercase(args[2]), ".json")
		convertBibliography(args[1], args[2], bibTeXFormat(), jsonFormat())
		return 0
	end

	if args[1] == "convert"
		_runConvertCLI(args[2 : end])
		return 0
	end

	auxPath = nothing
	libraries = String[]
	outputPath = nothing
	style = "auto"

	i = 1
	while i <= length(args)
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
