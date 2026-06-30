# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderDoiEntry(entry::ZettelEntry, format::BibliographyFormat)

Render a DOI-fetched entry in the same external representation style used by `entryToString`.
"""
function renderDoiEntry(entry::ZettelEntry, format::BibliographyFormat)
	text = entryToString(entry, format)
	if ! endswith(text, "\n")
		text *= "\n"
	end
	return text
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderQueriedEntry(entry::ZettelEntry)

Render one entry in compact human-readable form:
```
"The title"
F. Author, S. Author, ...
Journal year, volume number
arXiv:XXXXXXXX
doi: XXXXXXX
bibkey: author20XXa
```
"""
function renderQueriedEntry(entry::ZettelEntry)
	lines = String[]

	title = _queryFieldText(getTitle(entry))
	if ! isempty(title)
		push!(lines, "\"$(title)\"")
	end

	authorsLine = renderQueryAuthors(entry)
	if ! isempty(authorsLine)
		push!(lines, authorsLine)
	end

	journalLine = renderQueryVenue(entry)
	if ! isempty(journalLine)
		push!(lines, journalLine)
	end

	arxivId = queryArxivId(entry)
	if ! isempty(arxivId)
		push!(lines, "arXiv:$(arxivId)")
	end

	doi = _queryFieldText(getDOI(entry))
	if ! isempty(doi)
		push!(lines, "doi: $(doi)")
	end

	push!(lines, "bibkey: $(entry.key)")

	return join(lines, "\n") * "\n"
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderQueryAuthors(entry::ZettelEntry)

Render the author/collaboration line for query output.
"""
function renderQueryAuthors(entry::ZettelEntry)
	fields = entry.fields
	collaboration = _queryFieldText(get(fields, "collaboration", ""))
	onbehalf = _fieldIsTrue(get(fields, "onbehalf", ""))

	if ! isempty(collaboration)
		if onbehalf
			author = _queryFirstAuthor(entry)
			if isempty(author)
				return "et al. for $(collaboration)"
			end
			return "$(author) et al. for $(collaboration)"
		end
		return collaboration
	end

	authors = splitBibtexNames(getAuthors(entry))
	formatted = String[]
	for rawAuthor ∈ authors
		author = _queryPersonSummary(rawAuthor)
		if ! isempty(author)
			push!(formatted, author)
		end
	end

	return join(formatted, ", ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderQueryVenue(entry::ZettelEntry)

Render the journal/year/volume/number line for query output.
"""
function renderQueryVenue(entry::ZettelEntry)
	journal = _queryFieldText(getJournal(entry))
	year = _queryFieldText(getYear(entry))
	volume = _queryFieldText(getVolume(entry))
	number = _queryFieldText(getNumber(entry))

	parts = String[]
	if ! isempty(journal)
		push!(parts, journal)
	end
	if ! isempty(year)
		push!(parts, year)
	end
	if ! isempty(volume)
		push!(parts, volume)
	end
	if ! isempty(number)
		push!(parts, number)
	end

	return join(parts, ", ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	queryArxivId(entry::ZettelEntry)

Extract an arXiv identifier from `eprint`/`archivePrefix` fields.
"""
function queryArxivId(entry::ZettelEntry)
	eprint = _queryFieldText(getField(entry, "eprint"))
	if isempty(eprint)
		return ""
	end

	arxiv = replace(eprint, r"^arxiv:\s*"i => "")
	arxiv = strip(arxiv)
	prefix = lowercase(_queryFieldText(getField(entry, "archivePrefix")))
	if isempty(prefix) || prefix == "arxiv"
		return arxiv
	end

	return ""
end


@doc """
	_queryFirstAuthor(entry::ZettelEntry)

Return the first author as `F. Surname`.
"""
function _queryFirstAuthor(entry::ZettelEntry)
	authors = splitBibtexNames(getAuthors(entry))
	if isempty(authors)
		return ""
	end
	return _queryPersonSummary(first(authors))
end


@doc """
	_queryPersonSummary(rawName)

Convert one BibTeX person name to `F. Surname` format.
"""
function _queryPersonSummary(rawName::AbstractString)
	person = parseBibtexPerson(rawName)
	lastName = _queryFieldText(person.lastName)
	if isempty(lastName)
		lastName = _queryFieldText(rawName)
	end

	initials = String[]
	for token ∈ split(strip(person.firstName), r"\s+")
		t = strip(token)
		isempty(t) && continue
		push!(initials, string(uppercase(first(t)), "."))
	end
	for token ∈ split(strip(person.middleName), r"\s+")
		t = strip(token)
		isempty(t) && continue
		push!(initials, string(uppercase(first(t)), "."))
	end

	if isempty(initials)
		return lastName
	end
	if isempty(lastName)
		return join(initials, " ")
	end
	return "$(join(initials, " ")) $(lastName)"
end


@doc """
	_queryFieldText(text)

Normalise one field for query-mode plain-text printing.
"""
function _queryFieldText(text::AbstractString)
	return strip(decodeTex(stripOuterBraces(text)))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	renderPastedEntry(lib::ZettelLibrary, format::BibliographyFormat)
	renderPastedEntry(lib::ZettelLibrary, ::Type{<: BibliographyFormat})

Render pasted BibTeX entries as BibTeX / JSON / YAML.
"""
function renderPastedEntry(lib::ZettelLibrary, ::Type{BibtexFormat})
	io  = IOBuffer()
	for entry ∈ values(lib)
		println(io, entryToString(entry, BibtexFormat()))
		println(io)
	end
	return String(take!(io))
end

function renderPastedEntry(lib::ZettelLibrary, ::Type{JsonFormat})
	data = if length(lib) == 1
		entryToStructuredDict(first(values(lib)))
	else
		[entryToStructuredDict(entry) for entry ∈ values(lib)]
	end

	io = IOBuffer()
	JSON3.pretty(io, data, JSON3.AlignmentContext(; indent = 4))
	text = String(take!(io))
	if ! endswith(text, "\n")
		text *= "\n"
	end

	return text
end

function renderPastedEntry(lib::ZettelLibrary, ::Type{YamlFormat})
	data = if length(lib) == 1
		entryToStructuredDict(first(values(lib)))
	else
		[entryToStructuredDict(entry) for entry ∈ values(lib)]
	end
	
	text = YAML.write(normaliseYaml(data))
	if ! endswith(text, "\n")
		text *= "\n"
	end

	return text
end

function renderPastedEntry(lib::ZettelLibrary, format::BibliographyFormat) 
	return renderPastedEntry(lib, typeof(format))
end




# ----------------------------------------------------------------------------------------------- #
