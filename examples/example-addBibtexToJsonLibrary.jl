#!/usr/bin/env julia

using Printf
using Zettel


function usage()
	println("Usage: julia --project=. examples/addBibEntryJson.jl <libraryPath> [fileDir]")
	println("")
	println("Paste one BibTeX entry below and end input with a line containing only ';;'.")
	println("The script updates a JSON library in place, applies entry fixes, and keeps key order.")
end


function extractPastedBibtex()
	buffer = IOBuffer()
	for line ∈ eachline(stdin)
		if strip(line) == ";;"
			break
		end
		println(buffer, line)
	end

	text = String(take!(buffer))
	if isempty(strip(text))
		throw(ArgumentError("No BibTeX entry received."))
	end

	return text
end


function readSingleBibtexEntry(text::AbstractString)
	return mktempdir() do dir
		path = joinpath(dir, "entry.bib")
		write(path, text)
		lib = readBibtexLibrary(path)
		if length(lib) != 1
			throw(ArgumentError("Expected exactly one BibTeX entry."))
		end
		return first(values(lib))
	end
end


function fixSISSAJournals!(entry::ZettelEntry)
	sissaJournals = (
		"Journal of Cosmology and Astroparticle Physics",
		"Journal of High Energy Physics",
	)
	if entry.entryType == "article" && haskey(entry.fields, "journal") && haskey(entry.fields, "number")
		if strip(entry.fields["journal"]) ∈ sissaJournals
			entry.fields["volume"] = entry.fields["number"]
		end
	end
	return entry
end


function attachFile!(entry::ZettelEntry, libraryFolder::Union{Nothing, AbstractString}; warningsEnabled::Bool = false)
	if isnothing(libraryFolder)
		libraryFolder = "."
	end

	if hasField(entry, "file")
		if ! occursin(entry.key, entry.fields["file"]) && warningsEnabled
			@warn string(
				"Possible mismatch between entry key and associated file for entry with key: $(entry.key)\n",
				"  . key: $(entry.key)\n",
				"  . file: ", entry.fields["file"], "\n"
			)
		end
	else
		fileName = @sprintf("%s/files/%s/%s", libraryFolder, entry.key[1], entry.key)
		if isfile(fileName * ".pdf")
			fn = joinpath(libraryFolder, @sprintf(":%s.pdf:PDF", fileName))
			entry.fields["file"] = replace(fn, "$libraryFolder/" => "")
		elseif isfile(fileName * ".djvu")
			fn = joinpath(libraryFolder, @sprintf(":%s.djvu:djvu", fileName))
			entry.fields["file"] = replace(fn, "$libraryFolder/" => "")
		end
	end

	return entry
end


function main(args::Vector{String})
	if isempty(args) || any(arg -> arg ∈ ("-h", "--help"), args)
		usage()
		return 0
	end

	libraryPath = args[1]
	fileDir = length(args) ≥ 2 ? args[2] : nothing

	if ! isfile(libraryPath)
		throw(ArgumentError("Library file not found: $(libraryPath)"))
	end

	entryText = extractPastedBibtex()
	entry = readSingleBibtexEntry(entryText)
	fixSISSAJournals!(entry)
	attachFile!(entry, fileDir)
	bibtexText = entryToString(entry, BibtexFormat())
	output = IOBuffer()
	code = zettelCLI(; args = ["paste", "--to", "json", "--library", libraryPath], input = IOBuffer(bibtexText), output = output)
	inserted = readJsonString(String(take!(output)))
	newKey = only(keys(inserted))
	println("Inserted key: $(newKey)")

	return code
end


if abspath(PROGRAM_FILE) == @__FILE__
	exit(main(copy(ARGS)))
end
