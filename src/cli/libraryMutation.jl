# ----------------------------------------------------------------------------------------------- #
#
@doc """
	addEntriesToLibrary(incoming::ZettelLibrary, libraryPath::AbstractString)

Add entries from `incoming` into the library file at `libraryPath`, creating the library if it does not exist. 
Inserted entries receive generated keys based on first author or collaboration and publication year.
JSON libraries are updated with a direct text splice so the prepared entry is inserted in place without rebuilding the full file.
Returns a [`ZettelLibrary`](@ref) containing the prepared entries that were inserted.
"""
function addEntriesToLibrary(incoming::ZettelLibrary, libraryPath::AbstractString)
	format = identifyBibliographyFormat(libraryPath)
	if format isa JsonFormat
		return addEntriesToJsonLibrary(incoming, libraryPath)
	end

	lib = isfile(libraryPath) ? loadLibrary(libraryPath) : ZettelLibrary()
	existing = Set(String.(collect(keys(lib.entries))))
	inserted = ZettelLibrary()
	for entry ∈ values(incoming)
		updated = entryWithGeneratedLibraryKey(entry, existing)
		push!(lib, updated)
		push!(inserted, updated)
		push!(existing, updated.key)
	end

	saveLibrary(sort!(lib), libraryPath)
	return inserted
end


function entryWithGeneratedLibraryKey(entry::ZettelEntry, existing::Set{String})
	collabToken = first(collaborationTokenForGeneratedKey(entry.fields))
	useCollaboration = ! isnothing(collabToken) && shouldUseCollaborationForGeneratedKey(entry.fields)
	baseToken = useCollaboration ? collabToken : authorTokenForGeneratedKey(entry.fields)
	yearToken = yearTokenForGeneratedKey(entry.fields)
	key = nextAvailableGeneratedKey(baseToken, yearToken, existing)
	return ZettelEntry(key, entry.entryType, entry.fields)
end


@doc """
	jsonLibraryEntryLines(entry; trailingComma = false)

Render one prepared [`ZettelEntry`](@ref) as the indented JSON block used inside a JSON bibliography file.
"""
function jsonLibraryEntryLines(entry::ZettelEntry; trailingComma::Bool = false)
	io = IOBuffer()
	JSON3.pretty(io, entryToStructuredDict(entry), JSON3.AlignmentContext(; indent = 4))
	text = indentJson(String(take!(io)))
	lines = split(chomp(text), '\n')
	entryLines = ["\t" * line for line ∈ lines]
	if trailingComma
		entryLines[end] *= ","
	end
	return entryLines
end


@doc """
	jsonLibraryKeys(lines)

Extract the citation keys stored in a JSON bibliography file represented as lines of text.
"""
function jsonLibraryKeys(lines::AbstractVector{<: AbstractString})
	keys = Set{String}()
	for line ∈ lines
		trimmed = strip(line)
		if startswith(trimmed, "\"key\": ")
			keyText = strip(trimmed[length("\"key\": ") + 1 : end])
			if endswith(keyText, ",")
				keyText = chop(keyText)
			end
			push!(keys, String(JSON3.read(keyText)))
		end
	end
	return keys
end


function jsonLibraryEntryBounds(lines::AbstractVector{<: AbstractString}, key::AbstractString)
	expectedKeyLine = "\"key\": $(JSON3.write(key)),"
	for lineIndex ∈ eachindex(lines)
		if strip(lines[lineIndex]) == expectedKeyLine
			startLine = lineIndex
			while startLine > firstindex(lines) && lines[startLine] != "\t{"
				startLine -= 1
			end
			if lines[startLine] != "\t{"
				return nothing
			end

			endLine = lineIndex
			while endLine ≤ lastindex(lines) && ! (lines[endLine] == "\t}" || lines[endLine] == "\t},")
				endLine += 1
			end
			if endLine > lastindex(lines)
				return nothing
			end
			return (startLine, endLine)
		end
	end
	return nothing
end


function jsonLibraryAppendEntryLines(lines::AbstractVector{<: AbstractString}, entryLines::AbstractVector{<: AbstractString})
	closingBracketLine = findlast(line -> line == "]", lines)
	if isnothing(closingBracketLine)
		throw(ArgumentError("Invalid JSON library: missing closing bracket."))
	end

	lastEntryCloseLine = 0
	for lineIndex ∈ closingBracketLine - 1:-1:firstindex(lines)
		if lines[lineIndex] == "\t}" || lines[lineIndex] == "\t},"
			lastEntryCloseLine = lineIndex
			break
		end
	end

	updatedLines = copy(lines)
	if lastEntryCloseLine != 0 && updatedLines[lastEntryCloseLine] == "\t}"
		updatedLines[lastEntryCloseLine] = "\t},"
	end

	if lastEntryCloseLine == 0
		return vcat(updatedLines[1:1], entryLines, updatedLines[2:end])
	end

	return vcat(updatedLines[1:closingBracketLine - 1], entryLines, updatedLines[closingBracketLine:end])
end


function jsonLibraryReplaceEntryLines(lines::AbstractVector{<: AbstractString}, entryLines::AbstractVector{<: AbstractString}, bounds)
	startLine, endLine = bounds
	replacementLines = copy(entryLines)
	if endswith(lines[endLine], ",")
		replacementLines[end] *= ","
	end
	return vcat(lines[1:startLine - 1], replacementLines, lines[endLine + 1:end])
end


function addEntriesToJsonLibrary(incoming::ZettelLibrary, libraryPath::AbstractString)
	libraryText = isfile(libraryPath) ? read(libraryPath, String) : "[\n]\n"
	lines = split(chomp(libraryText), '\n')
	if isempty(lines)
		lines = ["[", "]"]
	end

	existing = jsonLibraryKeys(lines)
	inserted = ZettelLibrary()

	for entry ∈ values(incoming)
		updated = entryWithGeneratedLibraryKey(entry, existing)
		entryLines = jsonLibraryEntryLines(updated)
		bounds = jsonLibraryEntryBounds(lines, updated.key)
		if isnothing(bounds)
			lines = jsonLibraryAppendEntryLines(lines, entryLines)
		else
			lines = jsonLibraryReplaceEntryLines(lines, entryLines, bounds)
		end
		push!(inserted, updated)
		push!(existing, updated.key)
	end

	text = join(lines, '\n')
	if ! endswith(text, "\n")
		text *= "\n"
	end
	write(libraryPath, text)
	return inserted
end


# ----------------------------------------------------------------------------------------------- #
