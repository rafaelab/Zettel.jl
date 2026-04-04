# ----------------------------------------------------------------------------------------------- #
#
@doc """
	AuxData

Parsed information from a LaTeX `.aux` file.

# Fields
- `citations::Vector{String}`: citation keys in first-seen order
- `bibdata::Vector{String}`: bibliography data sources (as given in `\\bibdata{...}`)
- `bibstyle::Maybe{String}`: bibliography style name if present
- `citeAll::Bool`: whether `\\citation{*}` was encountered
"""
struct AuxData
	citations::Vector{String}
	bibdata::Vector{String}
	bibstyle::Maybe{String}
	citeAll::Bool
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	StyleSpec

Internal style configuration used for `.bbl` rendering.

# Fields
- `name::String`: style name
- `order::Symbol`: `:cite` to keep citation order, `:alpha` to sort by author/year/title
- `label::Symbol`: `:numeric` or `:alpha` label style for `\\bibitem`
- `variant::Symbol`: `:plain` or `:full` output formatting
"""
struct StyleSpec
	name::String
	order::Symbol      # :cite or :alpha
	label::Symbol      # :numeric or :alpha
	variant::Symbol    # :plain or :full
end


# ----------------------------------------------------------------------------------------------- #
#
const styleSpecsDict = Dict{String, StyleSpec}()


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	registerStyle(spec)

Register a bibliography style for `.bbl` generation.
"""
function registerStyle(spec::StyleSpec)
	styleSpecsDict[lowercase(spec.name)] = spec
	return spec
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	parseAuxFile(path)

Parse a LaTeX `.aux` file and return an `AuxData`.
This follows `\\@input{...}` references recursively and preserves citation order.

# Input
- `path::AbstractString`: path to the `.aux` file to parse.

# Output
- An `AuxData` struct containing parsed citations, bibliography data sources, and style information.

# Example

```julia
using Zettel

# Parse a LaTeX auxiliary file
aux = parseAuxFile("paper.aux")

# Inspect the results
println("Citations: ", aux.citations)
println("Bibliography sources: ", aux.bibdata)
println("Style: ", aux.bibstyle)
println("Cite all? ", aux.citeAll)

# Output example:
# Citations: String["Einstein1905", "Misner1973"]
# Bibliography sources: String["references"]
# Style: "plain"
# Cite all? false
```
"""
function parseAuxFile(path::AbstractString)
	citations = String[]
	citationSet = Set{String}()
	bibdata = String[]
	bibdataSet = Set{String}()
	bibstyleRef = Ref{Maybe{String}}(nothing)
	citeAllRef = Ref(false)
	visited = Set{String}()

	_parseAuxFile!(path, citations, citationSet, bibdata, bibdataSet, bibstyleRef, citeAllRef, visited)

	return AuxData(citations, bibdata, bibstyleRef[], citeAllRef[])
end


function _parseAuxFile!(path::AbstractString, citations::Vector{String}, citationSet::Set{String}, bibdata::Vector{String}, bibdataSet::Set{String}, bibstyleRef::Ref{Maybe{String}}, citeAllRef::Ref{Bool}, visited::Set{String})

	absPath = abspath(path)
	if absPath ∈ visited
		return nothing
	end
	push!(visited, absPath)
	isfile(path) || return nothing

	for line ∈ eachline(path)
		for m ∈ eachmatch(r"\\citation\{([^}]*)\}", line)
			raw = m.captures[1]
			for key ∈ split(raw, ",")
				k = strip(key)
				empty = isempty(k)
				if empty
					continue
				end
				if k == "*"
					citeAllRef[] = true
				elseif ! (k ∈ citationSet)
					push!(citations, k)
					push!(citationSet, k)
				end
			end
		end

		for m ∈ eachmatch(r"\\bibdata\{([^}]*)\}", line)
			raw = m.captures[1]
			for name ∈ split(raw, ",")
				n = strip(name)
				isempty(n) && continue
				if ! (n ∈ bibdataSet)
					push!(bibdata, n)
					push!(bibdataSet, n)
				end
			end
		end

		if isnothing(bibstyleRef[])
			m = match(r"\\bibstyle\{([^}]*)\}", line)
			if ! isnothing(m)
				bibstyleRef[] = strip(m.captures[1])
			end
		end

		for m ∈ eachmatch(r"\\@input\{([^}]*)\}", line)
			sub = joinpath(dirname(path), m.captures[1])
			_parseAuxFile!(sub, citations, citationSet, bibdata, bibdataSet, bibstyleRef, citeAllRef, visited)
		end
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeBblFromAux(auxPath; libraryFiles = nothing, outputPath = nothing, style = "auto")

Generate a `.bbl` file from a LaTeX `.aux` file using a [`ZettelLibrary`](@ref).
If `libraryFiles` is not provided, the function uses `\\bibdata{...}` entries from the `.aux` file, resolving `name.json` (preferred), `name.yaml`, `name.yml`, or `name.bib` relative to the `.aux` directory.
If `style` is `"auto"`, the function uses `\\bibstyle{...}` from the `.aux` when present, falling back to `"plain"` otherwise.

# Input
- `auxPath::AbstractString`: path to the `.aux` file to process.
- `libraryFiles::Maybe{Vector{String}}`: optional explicit list of library files to use instead of those referenced from the `.aux`.
- `outputPath::Maybe{AbstractString}`: optional path to write the `.bbl` output to (defaults to same name as `.aux` with `.bbl` extension).
- `style::AbstractString`: bibliography style name to use for formatting (e.g. `"plain"`, `"alpha"`, or `"ieeetr"`).

# Output
- Returns a named tuple with `outputPath`, `absent`, and `usedKeys`.

# Example

```julia
using Zettel

# Typical LaTeX workflow
# 1. Run pdflatex to generate paper.aux
# 2. Generate paper.bbl from the library
result = writeBblFromAux("paper.aux"; libraryFiles = ["references.json"])

println("Output: ", result.outputPath)
println("Used keys: ", result.usedKeys)
println("Missing keys: ", result.absent)

# With custom style
result = writeBblFromAux(
    "paper.aux";
    libraryFiles = ["references.json"],
    outputPath = "paper.bbl",
    style = "alpha"
)

# The .bbl file can now be included in paper.tex via \\input{paper.bbl}
```
"""
function writeBblFromAux(auxPath::AbstractString; libraryFiles = nothing, outputPath = nothing, style::AbstractString = "auto")
	aux = parseAuxFile(auxPath)
	libFiles = _resolveLibraryFiles(auxPath, aux.bibdata, libraryFiles)
	lib = _loadLibraries(libFiles)
	styleName = _resolveStyleName(style, aux.bibstyle)

	keys = aux.citeAll ? collect(keys(lib)) : aux.citations
	keys = _uniquePreserve(keys)

	used = String[]
	absent = String[]
	entries = Vector{Maybe{ZettelEntry}}()
	for key ∈ keys
		if haskey(lib, key)
			push!(entries, lib[key])
			push!(used, key)
		else
			push!(entries, nothing)
			push!(absent, key)
		end
	end

	outPath = isnothing(outputPath) ? _defaultBblPath(auxPath) : outputPath
	write(outPath, _renderBbl(keys, entries; style = styleName))

	return (outputPath = outPath, absent = absent, usedKeys = used)
end


# ----------------------------------------------------------------------------------------------- #
#
function _defaultBblPath(auxPath::AbstractString)
	base = splitext(auxPath)[1]
	return string(base, ".bbl")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_resolveLibraryFiles(auxPath, bibdata, libraryFiles)

Helper that resolves bibliography source file paths referenced from an `.aux` file.
If `libraryFiles` is provided it is normalised; otherwise the function locates `name.json`, `name.yaml`, `name.yml` or `name.bib` next to the `.aux` file.

# Input
- `auxPath::AbstractString`: path to the `.aux` file (used for resolving relative paths).
- `bibdata::Vector{String}`: bibliography source names from the `.aux` file.
- `libraryFiles`: optional explicit list of library files to use instead of those referenced from the `.aux`.

# Output
- A `Vector{String}` of resolved file paths to load for the bibliography.
"""
function _resolveLibraryFiles(auxPath::AbstractString, bibdata::Vector{String}, libraryFiles)
	if ! isnothing(libraryFiles)
		return _normaliseLibraryFiles(libraryFiles)
	end

	if isempty(bibdata)
		throw(ArgumentError("No bibliography sources found in aux file and no libraryFiles provided."))
	end

	formats = (".json", ".yaml", ".yml", ".bib")

	auxDir = dirname(auxPath)
	resolved = String[]

	for name ∈ bibdata
		candidates = String[]

		fileExt = splitext(name)[2]
		if fileExt ∈ formats
			push!(candidates, name)
		else
			for ext ∈ formats
				push!(candidates, string(name, ext))
			end
		end

		found = nothing
		for c ∈ candidates
			path = normpath(joinpath(auxDir, c))
			if isfile(path)
				found = path
				break
			end
		end

		if isnothing(found)
			throw(ArgumentError("Bibliography source not found for $(name) (expected .json, .yaml, .yml or .bib next to aux file)."))
		end
		push!(resolved, found)
	end

	return resolved
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_normaliseLibraryFiles(libraryFiles)

Normalise a libraryFiles argument which may contain comma-separated paths into a flat `Vector{String}` of file paths.

# Input
- `libraryFiles`: a `Vector{String}` where each string may be a single file path or a comma-separated list of file paths.

# Output
- A `Vector{String}` containing all individual file paths with whitespace stripped.
"""
function _normaliseLibraryFiles(libraryFiles)
	files = String[]
	for f ∈ libraryFiles
		if occursin(",", f)
			append!(files, [strip(x) for x ∈ split(f, ",") if ! isempty(strip(x))])
		else
			push!(files, f)
		end
	end
	return files
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_loadLibraries(files)

Load multiple bibliography files and merge their entries into a single `ZettelLibrary`.

# Input
- `files::Vector{String}`: list of file paths to load.

# Output
- A `ZettelLibrary` containing all entries from the provided files.
"""
function _loadLibraries(files::Vector{String})
	lib = ZettelLibrary()
	for f ∈ files
		l = _readLibraryFile(f)
		for entry ∈ values(l)
			push!(lib, entry)
		end
	end
	return lib
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_readLibraryFile(path)

Wrapper for `loadLibrary` that centralises reading a single library file.

# Input
- `path::AbstractString`: path to the library file to load.

# Output
- A `ZettelLibrary` containing the entries from the specified file.
"""
function _readLibraryFile(path::AbstractString)
	return loadLibrary(path)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_uniquePreserve(items)

Return a new vector preserving first-seen order but removing duplicates.
"""
function _uniquePreserve(items::Vector{String})
	seen = Set{String}()
	out = String[]
	for item ∈ items
		if item ∉ seen
			push!(seen, item)
			push!(out, item)
		end
	end
	return out
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_renderBbl(keys, entries; style = "plain")

Render the `.bbl` document text for the given keys and corresponding entries using the provided style specification.

# Input
- `keys::Vector{String}`: citation keys in the order they should appear in the `.bbl`.
- `entries::Vector{Maybe{ZettelEntry}}`: corresponding entries for the keys (may contain `nothing` for missing entries).
- `style::AbstractString`: bibliography style name to use for formatting (e.g. `"plain"`, `"alpha"`, or `"ieeetr"`).

# Output
- A string containing the full contents of the `.bbl` file to be written.
"""
function _renderBbl(keys::Vector{String}, entries::Vector{Maybe{ZettelEntry}}; style::AbstractString = "plain")
	spec = _getStyleSpec(style)
	(keys, entries) = _orderEntries(keys, entries, spec)
	n = length(keys)
	lines = String[]

	push!(lines, "\\begin{thebibliography}{$(n)}")
	for (key, entry) ∈ zip(keys, entries)
		push!(lines, "")
		push!(lines, _bibitemLine(key, entry, spec))
		if isnothing(entry)
			push!(lines, "Absent entry for $(key).")
		else
			push!(lines, _formatEntry(entry; variant = spec.variant))
		end
	end
	push!(lines, "")
	push!(lines, "\\end{thebibliography}")

	return join(lines, "\n")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_getStyleSpec(style)

Lookup the `StyleSpec` for `style` or throw an informative error with available style names.

# Input
- `style::AbstractString`: style name to look up.

# Output
- The `StyleSpec` corresponding to the requested style name.
"""
function _getStyleSpec(style::AbstractString)
	key = lowercase(style)
	if ! haskey(styleSpecsDict, key)
		available = sort(collect(keys(styleSpecsDict)))
		throw(ArgumentError("Unknown style: $(style). Available: $(join(available, ", "))"))
	end

	return styleSpecsDict[key]
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_resolveStyleName(style, bibstyle)

Resolve the effective style name. If `style == "auto"`, prefer `bibstyle` when present, otherwise fall back to `"plain"`.

# Input
- `style::AbstractString`: requested style name (e.g. `"plain"`, `"alpha"`, `"auto"`).
- `bibstyle::Maybe{String}`: style name from `\\bibstyle{...}` in the `.aux` file, if present.

# Output
- The effective style name to use.
"""
function _resolveStyleName(style::AbstractString, bibstyle::Maybe{String})
	key = lowercase(strip(style))
	if key == "auto"
		if isnothing(bibstyle) || isempty(strip(bibstyle))
			return "plain"
		end
		return String(bibstyle)
	end
	return String(style)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_orderEntries(keys, entries, spec)

Order entries according to the `StyleSpec`. 
Returns `(keys, entries)` in the requested ordering (citation order or sorted by author/year/title).

# Input
- `keys::Vector{String}`: citation keys in the order they were cited.
- `entries::Vector{Maybe{ZettelEntry}}`: corresponding entries for the keys (may contain `nothing` for missing entries).
- `spec::StyleSpec`: style specification that determines the ordering.

# Output
- A tuple `(orderedKeys, orderedEntries)` where the keys and entries are ordered according to the style specification.
"""
function _orderEntries(keys::Vector{String}, entries::Vector{Maybe{ZettelEntry}}, spec::StyleSpec)
	if spec.order == :cite
		return (keys, entries)
	end

	idx = collect(1 : length(keys))
	sort!(idx; by = i -> _entrySortKey(entries[i], keys[i]))

	return (keys[idx], entries[idx])
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_entrySortKey(entry, key)

Compute a sorting key for an entry used when ordering entries by author/year/title.
Missing entries get a sentinel key that places them last.

# Input
- `entry::Maybe{ZettelEntry}`: the entry to compute the sort key for (may be `nothing`).
- `key::AbstractString`: the citation key for the entry (used as a tiebreaker).

# Output
- A tuple that can be used as a sorting key, typically `(author, year, title, key)`, with appropriate handling for missing entries.
"""
function _entrySortKey(entry::Maybe{ZettelEntry}, key::AbstractString)
	if isnothing(entry)
		return ("~", key)
	end
	author = lowercase(getAuthors(entry))
	year = getYear(entry)
	title = lowercase(getTitle(entry))
	return (author, year, title, key)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_bibitemLine(key, entry, spec)

Format the `\\bibitem` line for a single bibliography entry according to `spec`.

# Input
- `key::AbstractString`: the citation key for the entry.
- `entry::Maybe{ZettelEntry}`: the entry corresponding to the key (may be `nothing` if the key was cited but not found in the library).
- `spec::StyleSpec`: the style specification that determines how to format the `\\bibitem` line.

# Output
- A string containing the formatted `\\bibitem` line for the entry.
"""
function _bibitemLine(key::AbstractString, entry::Maybe{ZettelEntry}, spec::StyleSpec)
	if spec.label == :alpha
		label = _alphaLabel(entry, key)
		return "\\bibitem[$(label)]{$(key)}"
	end
	return "\\bibitem{$(key)}"
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_alphaLabel(entry, key)

Construct an alpha-style label (e.g. first three letters of last name + year) for `\\bibitem` when the style requires alphabetic labels.

# Input
- `entry::Maybe{ZettelEntry}`: the entry to construct the label for (may be `nothing` if the entry was not found).
- `key::AbstractString`: the citation key for the entry (used as a fallback if the entry is missing or lacks author/year information).

# Output
- A string containing the alpha-style label for the entry, or the citation key if the entry is missing or lacks sufficient information for constructing a label.
"""
function _alphaLabel(entry::Maybe{ZettelEntry}, key::AbstractString)
	if isnothing(entry)
		return key
	end

	last = _firstAuthorLastName(getAuthors(entry))
	year = getYear(entry)
	if isempty(last)
		return key
	end

	base = length(last) > 3 ? last[1 : 3] : last
	if ! isempty(year)
		yy = length(year) ≥ 2 ? year[end - 1 : end] : year
		return string(base, yy)
	end

	return base
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_firstAuthorLastName(authors)

Return the last name of the first author from an `authors` string in `BibTeX`-style format (e.g. "Surname, Given" or "Given Surname").

# Input
- `authors::AbstractString`: the raw authors string from a bibliography entry, typically in `BibTeX` format.

# Output
- The last name of the first author, or an empty string if it cannot be determined.
"""
function _firstAuthorLastName(authors::AbstractString)
	if isempty(authors)
		return ""
	end
	firstPart = split(authors, " and ")[1]
	if occursin(",", firstPart)
		return strip(split(firstPart, ",")[1])
	end
	parts = split(firstPart)
	return isempty(parts) ? "" : strip(parts[end])
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_formatEntry(entry; variant = :plain)

Choose an appropriate textual formatting for an entry according to its type and the requested `variant` (`:plain` or `:full`).

# Input
- `entry::ZettelEntry`: the bibliography entry to format.
- `variant::Symbol`: the formatting variant to use, either `:plain` for compact formatting suitable for `.bbl` output, or `:full` for a verbose key:value style rendering of all available fields.

# Output
- A string containing the formatted representation of the entry according to the specified variant.
"""
function _formatEntry(entry::ZettelEntry; variant::Symbol = :plain)
	if variant == :full
		return _formatFullEntry(entry)
	end
	return _formatPlainEntry(entry)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_formatPlainEntry(entry)

Produce a compact, plain-text representation for common entry types (article, book, inproceedings) suitable for `.bbl` output.

# Input
- `entry::ZettelEntry`: the bibliography entry to format.

# Output
- A string containing the formatted representation of the entry according to its type, or a generic fallback format if the type is not recognised.
"""
function _formatPlainEntry(entry::ZettelEntry)
	t = lowercase(entry.entryType)
	if t == "article"
		return _formatArticle(entry)
	elseif t == "book"
		return _formatBook(entry)
	elseif t == "inproceedings" || t == "incollection"
		return _formatInProceedings(entry)
	else
		return _formatGeneric(entry)
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_formatFullEntry(entry)

Produce a verbose key:value style rendering of all available fields of `entry`.

# Input
- `entry::ZettelEntry`: the bibliography entry to format.

# Output
- A string containing all non-empty fields of the entry in a key:value format, ordered by a preferred field order followed by any additional fields in arbitrary order.
"""
function _formatFullEntry(entry::ZettelEntry)
	preferred = ("author", "title", "journal", "booktitle", "publisher", "year", "volume", "number", "pages", "doi", "url", "isbn", "note")
	parts = String[]

	for field ∈ preferred
		val = getField(entry, field)
		isempty(val) && continue
		push!(parts, string(field, ": ", val))
	end

	for field ∈ getAllFields(entry)
		field ∈ preferred && continue
		val = getField(entry, field)
		isempty(val) && continue
		push!(parts, string(field, ": ", val))
	end

	if isempty(parts)
		return "Unformatted entry."
	end

	return join(parts, "; ") * "."
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_formatArticle(entry)

Format an `article` entry for `.bbl` output (authors, title, journal, etc.).

# Input
- `entry::ZettelEntry`: the bibliography entry to format (expected to be of type `article`).

# Output
- A string containing the formatted representation of the article entry, including authors, title, journal, volume, number, pages, and year as available.
"""
function _formatArticle(entry::ZettelEntry)
	author = getAuthors(entry)
	title = getTitle(entry)
	journal = getJournal(entry)
	volume = getVolume(entry)
	number = getNumber(entry)
	pages = getPages(entry)
	year = getYear(entry)

	parts = String[]
	! isempty(author) && push!(parts, string(author, "."))
	! isempty(title) && push!(parts, string(title, "."))

	if ! isempty(journal)
		j = "\\emph{$(journal)}"
		if ! isempty(volume)
			j *= ", " * volume
			if ! isempty(number)
				j *= "(" * number * ")"
			end
		end
		if ! isempty(pages)
			j *= ":" * pages
		end
		if ! isempty(year)
			j *= ", " * year
		end
		j *= "."
		push!(parts, j)
	elseif ! isempty(year)
		push!(parts, string(year, "."))
	end

	return join(parts, " ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_formatBook(entry)

Format a `book` entry for `.bbl` output (authors, title, publisher, year).

# Input
- `entry::ZettelEntry`: the bibliography entry to format (expected to be of type `book`).

# Output
- A string containing the formatted representation of the book entry, including authors, title, publisher, and year as available.
"""
function _formatBook(entry::ZettelEntry)
	author = getAuthors(entry)
	title = getTitle(entry)
	publisher = getPublisher(entry)
	year = getYear(entry)

	parts = String[]
	! isempty(author) && push!(parts, string(author, "."))
	! isempty(title) && push!(parts, string("\\emph{", title, "}."))

	pubParts = String[]
	! isempty(publisher) && push!(pubParts, publisher)
	! isempty(year) && push!(pubParts, year)
	if ! isempty(pubParts)
		push!(parts, string(join(pubParts, ", "), "."))
	end

	return join(parts, " ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_formatInProceedings(entry)

Format an `inproceedings`/`incollection` entry for `.bbl` output.

# Input
- `entry::ZettelEntry`: the bibliography entry to format (expected to be of type `inproceedings` or `incollection`).

# Output
- A string containing the formatted representation of the inproceedings/incollection entry, including authors, title, booktitle, pages, and year as available.
"""
function _formatInProceedings(entry::ZettelEntry)
	author = getAuthors(entry)
	title = getTitle(entry)
	booktitle = getField(entry, "booktitle")
	pages = getPages(entry)
	year = getYear(entry)

	parts = String[]
	! isempty(author) && push!(parts, string(author, "."))
	! isempty(title) && push!(parts, string(title, "."))

	if ! isempty(booktitle)
		bt = string("In \\emph{", booktitle, "}")
		if ! isempty(pages)
			bt *= ", pp. " * pages
		end
		if ! isempty(year)
			bt *= ", " * year
		end
		bt *= "."
		push!(parts, bt)
	elseif ! isempty(year)
		push!(parts, string(year, "."))
	end

	return join(parts, " ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_formatGeneric(entry)

Fallback generic formatter for entry types not handled explicitly.

# Input
- `entry::ZettelEntry`: the bibliography entry to format.

# Output
- A string containing a simple concatenation of the authors, title, year, and note fields if present, or a placeholder message if none of these fields are available.
"""
function _formatGeneric(entry::ZettelEntry)
	author = getAuthors(entry)
	title = getTitle(entry)
	year = getYear(entry)
	note = getField(entry, "note")

	parts = String[]
	if ! isempty(author) 
		push!(parts, string(author, "."))
	end
	if ! isempty(title)
		push!(parts, string(title, "."))
	end
	if ! isempty(year)
		push!(parts, string(year, "."))
	end
	if ! isempty(note)
		push!(parts, string(note, "."))
	end

	if isempty(parts)
		return "Unformatted entry."
	end
	
	return join(parts, " ")
end


# ----------------------------------------------------------------------------------------------- #
