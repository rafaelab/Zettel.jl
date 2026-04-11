using Zettel



###################################################################################################
#                                         Helper functions                                        #
###################################################################################################


function looksLikeBibPath(path::AbstractString)
	return endswith(lowercase(path), ".bib")
end

function formatToken(token::AbstractString)
	return fileExtensionFromFormat(token)
end

function isBibRelated(args::Vector{String})
	if isempty(args)
		return false
	end
	cmd = args[1]

	# legacy 2-arg mode: zettel input.bib output.json
	if length(args) == 2 && ! startswith(args[1], "-") && ! startswith(args[2], "-")
		return looksLikeBibPath(args[1]) || looksLikeBibPath(args[2])
	end

	# paste always parses BibTeX from stdin
	if cmd == "paste"
		return true
	end

	# libupdate always parses BibTeX and updates a .bib library
	if cmd == "libupdate"
		return true
	end

	# DOI flows depend on runtime HTTP/Python behavior; keep them on interpreter path
	if cmd == "doi" || (startswith(cmd, "10.") && occursin("/", cmd))
		return true
	end

	if cmd == "convert"
		if length(args) < 3
			return false
		end
		inputPath = args[2]
		outputPath = args[3]
		fromType = nothing
		toType = nothing

		i = 4
		while i ≤ length(args)
			arg = args[i]
			if arg == "-f" || arg == "--from"
				i += 1
				if i ≤ length(args) 
					fromType = formatToken(args[i])
				end
			elseif arg == "-t" || arg == "--to"
				i += 1
				if i ≤ length(args)
					toType = formatToken(args[i])
				end
			end
			i += 1
		end

		if isnothing(fromType)
			fromType = looksLikeBibPath(inputPath) ? "bib" : nothing
		end
		if isnothing(toType)
			toType = looksLikeBibPath(outputPath) ? "bib" : nothing
		end

		return fromType == "bib" || toType == "bib"
	end

	# AUX mode can become BibTeX-backed if any library path is .bib.
	i = 1
	while i ≤ length(args)
		arg = args[i]
		if arg == "-l" || arg == "--library"
			i += 1
			i ≤ length(args) || break
			if looksLikeBibPath(args[i])
				return true
			end
		end
		i += 1
	end

	return false
end

function runViaInterpreter(args::Vector{String})
	juliaBin = get(ENV, "JULIA_BIN", "julia")
	projectRoot = normpath(joinpath(@__DIR__, ".."))
	snippet = "using Zettel; exit(Zettel.zettelCLI(; args = ARGS))"
	cmd = `$juliaBin --project=$projectRoot --compile=min -O0 -e $snippet -- $args`
	proc = run(Cmd(cmd; ignorestatus = true))
	return proc.exitcode
end


###################################################################################################
#                                      Main CLI Entrypoint                                        #
###################################################################################################

function main(args::Vector{String})
	if isBibRelated(args)
		return runViaInterpreter(args)
	end
	return Zettel.zettelCLI(; args = args)
end

(@main)(args) = main(args)
