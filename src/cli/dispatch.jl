export
	zettelCLI


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
		runConvertCLI(args[2 : end]; output = output)
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
		inputPath = args[1]
		outputPath = args[2]
		println(output, "Converting $(inputPath) -> $(outputPath)")
		convertBibliography(inputPath, outputPath, bibliographyFormat(inputPath), bibliographyFormat(outputPath))
		println(output, "Wrote $(outputPath)")
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
