# ----------------------------------------------------------------------------------------------- #
#
@doc """
	AuxData

Parsed information from a LaTeX `.aux` file.

# Fields
- `citations::Vector{String}`: citation keys in first-seen order
- `bibdata::Vector{String}`: bibliography data sources (as given in `\\bibdata{...}`)
- `bibstyle::Union{Nothing,String}`: bibliography style name if present
- `citeAll::Bool`: whether `\\citation{*}` was encountered
"""
struct AuxData
	citations::Vector{String}
	bibdata::Vector{String}
	bibstyle::Union{Nothing, String}
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
const STYLE_SPECS = Dict{String, StyleSpec}()


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	registerStyle(spec)

Register a bibliography style for `.bbl` generation.
"""
function registerStyle(spec::StyleSpec)
	STYLE_SPECS[lowercase(spec.name)] = spec
	return spec
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	parseAuxFile(path)

Parse a LaTeX `.aux` file and return an [`AuxData`](@ref).
This follows `\\@input{...}` references recursively and preserves citation order.
"""
function parseAuxFile(path::AbstractString)
	citations = String[]
	citationSet = Set{String}()
	bibdata = String[]
	bibdataSet = Set{String}()
	bibstyleRef = Ref{Union{Nothing, String}}(nothing)
	citeAllRef = Ref(false)
	visited = Set{String}()

	_parseAuxFile!(path, citations, citationSet, bibdata, bibdataSet, bibstyleRef, citeAllRef, visited)
	return AuxData(citations, bibdata, bibstyleRef[], citeAllRef[])
end


# ----------------------------------------------------------------------------------------------- #
#
function _parseAuxFile!(path::AbstractString, citations::Vector{String}, citationSet::Set{String}, bibdata::Vector{String}, bibdataSet::Set{String}, bibstyleRef::Ref{Union{Nothing, String}}, citeAllRef::Ref{Bool}, visited::Set{String})

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

If `libraryFiles` is not provided, the function uses `\\bibdata{...}` entries from the `.aux`
file, resolving `name.json` (preferred) or `name.bib` relative to the `.aux` directory.

If `style` is `"auto"`, the function uses `\\bibstyle{...}` from the `.aux` when present,
falling back to `"plain"` otherwise.

Returns a named tuple with `outputPath`, `absent`, and `usedKeys`.
"""
function writeBblFromAux(auxPath::AbstractString; libraryFiles = nothing, outputPath = nothing, style::AbstractString = "auto")
	aux = parseAuxFile(auxPath)
	libFiles = _resolveLibraryFiles(auxPath, aux.bibdata, libraryFiles)
	lib = _loadLibraries(libFiles)
	styleName = _resolveStyleName(style, aux.bibstyle)

	keys = if aux.citeAll
		collect(keys(lib))
	else
		aux.citations
	end
	keys = _uniquePreserve(keys)

	used = String[]
	absent = String[]
	entries = Vector{Union{ZettelEntry, Nothing}}()
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
function _resolveLibraryFiles(auxPath::AbstractString, bibdata::Vector{String}, libraryFiles)
	if ! isnothing(libraryFiles)
		return _normalizeLibraryFiles(libraryFiles)
	end

	if isempty(bibdata)
		throw(ArgumentError("No bibliography sources found in aux file and no libraryFiles provided."))
	end

	auxDir = dirname(auxPath)
	resolved = String[]

	for name ∈ bibdata
		candidates = String[]
		if endswith(lowercase(name), ".json") || endswith(lowercase(name), ".bib")
			push!(candidates, name)
		else
			push!(candidates, string(name, ".json"))
			push!(candidates, string(name, ".bib"))
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
			throw(ArgumentError("Bibliography source not found for $(name) (expected .json or .bib next to aux file)."))
		end
		push!(resolved, found)
	end

	return resolved
end


# ----------------------------------------------------------------------------------------------- #
#
function _normalizeLibraryFiles(libraryFiles)
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
function _readLibraryFile(path::AbstractString)
	if endswith(lowercase(path), ".json")
		return readJsonLibrary(path)
	elseif endswith(lowercase(path), ".bib")
		return readBibTeX(path)
	else
		throw(ArgumentError("Unsupported bibliography file extension: $(path)"))
	end
end


# ----------------------------------------------------------------------------------------------- #
#
function _uniquePreserve(items::Vector{String})
	seen = Set{String}()
	out = String[]
	for item ∈ items
		if ! (item ∈ seen)
			push!(seen, item)
			push!(out, item)
		end
	end
	return out
end


# ----------------------------------------------------------------------------------------------- #
#
function _renderBbl(keys::Vector{String}, entries::Vector{Union{ZettelEntry, Nothing}}; style::AbstractString = "plain")
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
function _getStyleSpec(style::AbstractString)
	key = lowercase(style)
	if ! haskey(STYLE_SPECS, key)
		available = sort(collect(keys(STYLE_SPECS)))
		throw(ArgumentError("Unknown style: $(style). Available: $(join(available, ", "))"))
	end
	return STYLE_SPECS[key]
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_resolveStyleName(style, bibstyle)

Resolve the effective style name. If `style == "auto"`, prefer `bibstyle` when present,
otherwise fall back to `"plain"`.
"""
function _resolveStyleName(style::AbstractString, bibstyle::Union{Nothing, String})
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
function _orderEntries(keys::Vector{String}, entries::Vector{Union{ZettelEntry, Nothing}}, spec::StyleSpec)
	if spec.order == :cite
		return (keys, entries)
	end

	idx = collect(1:length(keys))
	sort!(idx; by = i -> _entrySortKey(entries[i], keys[i]))
	return (keys[idx], entries[idx])
end


# ----------------------------------------------------------------------------------------------- #
#
function _entrySortKey(entry::Union{ZettelEntry, Nothing}, key::AbstractString)
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
function _bibitemLine(key::AbstractString, entry::Union{ZettelEntry, Nothing}, spec::StyleSpec)
	if spec.label == :alpha
		label = _alphaLabel(entry, key)
		return "\\bibitem[$(label)]{$(key)}"
	end
	return "\\bibitem{$(key)}"
end


# ----------------------------------------------------------------------------------------------- #
#
function _alphaLabel(entry::Union{ZettelEntry, Nothing}, key::AbstractString)
	if isnothing(entry)
		return key
	end

	last = _firstAuthorLastName(getAuthors(entry))
	year = getYear(entry)
	if isempty(last)
		return key
	end

	base = length(last) > 3 ? last[1:3] : last
	if ! isempty(year)
		yy = length(year) >= 2 ? year[end-1:end] : year
		return string(base, yy)
	end
	return base
end


# ----------------------------------------------------------------------------------------------- #
#
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
function _formatEntry(entry::ZettelEntry; variant::Symbol = :plain)
	if variant == :full
		return _formatFullEntry(entry)
	end
	return _formatPlainEntry(entry)
end


# ----------------------------------------------------------------------------------------------- #
#
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
function _formatFullEntry(entry::ZettelEntry)
	preferred = ["author", "title", "journal", "booktitle", "publisher", "year", "volume", "number", "pages", "doi", "url", "isbn", "note"]
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
function _formatGeneric(entry::ZettelEntry)
	author = getAuthors(entry)
	title = getTitle(entry)
	year = getYear(entry)
	note = getField(entry, "note")

	parts = String[]
	! isempty(author) && push!(parts, string(author, "."))
	! isempty(title) && push!(parts, string(title, "."))
	! isempty(year) && push!(parts, string(year, "."))
	! isempty(note) && push!(parts, string(note, "."))

	if isempty(parts)
		return "Unformatted entry."
	end
	return join(parts, " ")
end


# ----------------------------------------------------------------------------------------------- #
