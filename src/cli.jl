# ----------------------------------------------------------------------------------------------- #
#
function _cliUsage(; io::IO = stdout)
	println(io, "Usage: zettel <auxfile> [options]")
	println(io, "       zettel <input.bib> <output.json>")
	println(io, "")
	println(io, "Options:")
	println(io, "  -l, --library <file>   Path to a .json or .bib library (repeatable)")
	println(io, "  -o, --output <file>    Output .bbl path (default: <auxfile>.bbl)")
	println(io, "  -s, --style <name>     Bibliography style (default: auto -> \\bibstyle{...} or plain)")
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
		bibTeXToJson(args[1], args[2])
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

	isnothing(auxPath) && throw(ArgumentError("No aux file provided."))

	result = writeBblFromAux(auxPath; libraryFiles = isempty(libraries) ? nothing : libraries, outputPath = outputPath, style = style)

	absent = hasproperty(result, :absent) ? result.absent : String[]

	if ! isempty(absent)
		println(stderr, "Warning: absent entries for keys: ", join(absent, ", "))
	end

	return 0
end
