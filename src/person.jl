export
	PersonName,
	personRoles


# ----------------------------------------------------------------------------------------------- #
#
const personRoles = ("author", "editor", "translator")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	PersonName

Simple representation of one person's name.
"""
struct PersonName
	firstName::String
	middleName::String
	lastName::String
	suffix::String
end

PersonName(firstName::String, middleName::String, lastName::String) = PersonName(firstName, middleName, lastName, "")
PersonName(firstName::String, lastName::String) = PersonName(firstName, "", lastName, "")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	splitBibtexNames(nameLine)

Split a BibTeX name line on ` and ` while respecting brace depth.
"""
function splitBibtexNames(nameLine::AbstractString)
	line = strip(String(nameLine))
	if isempty(line)
		return String[]
	end

	parts = String[]
	buffer = IOBuffer()
	depth = 0
	i = firstindex(line)
	while i ≤ lastindex(line)
		c = line[i]
		if c == '{'
			depth += 1
		elseif c == '}'
			depth = max(0, depth - 1)
		end

		if depth == 0 && startswith(SubString(line, i), " and ")
			part = strip(String(take!(buffer)))
			if ! isempty(part)
				push!(parts, part)
			end
			i = nextind(line, i, 5)
			continue
		end

		print(buffer, c)
		i = nextind(line, i)
	end

	lastPart = strip(String(take!(buffer)))
	if ! isempty(lastPart)
		push!(parts, lastPart)
	end

	return parts
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	parseBibtexPerson(nameText)

Parse one BibTeX name string into a [`PersonName`](@ref).
"""
function parseBibtexPerson(nameText::AbstractString)
	name = strip(stripOuterBraces(nameText))
	if isempty(name)
		return PersonName("", "", "", "")
	end

	commaParts = split(name, ","; limit = 2)
	if length(commaParts) == 2
		last = decodeTex(strip(stripOuterBraces(commaParts[1])))
		given = decodeTex(strip(stripOuterBraces(commaParts[2])))
		first, middle = splitGivenName(given)
		return PersonName(first, middle, last, "")
	end

	words = split(name, r"\s+")
	if length(words) == 1
		last = decodeTex(strip(stripOuterBraces(words[1])))
		return PersonName("", "", last, "")
	end

	given = decodeTex(join(words[1 : end - 1], " "))
	first, middle = splitGivenName(given)
	last = decodeTex(strip(stripOuterBraces(words[end])))

	return PersonName(first, middle, last, "")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	formatBibtexPerson(person)

Format a [`PersonName`](@ref) as one BibTeX person string.
"""
function formatBibtexPerson(person::PersonName)
	first = strip(person.firstName)
	middle = strip(person.middleName)
	last = strip(person.lastName)
	given = strip(join(filter(! isempty, [first, middle]), " "))

	if isempty(last)
		return given
	elseif isempty(given)
		return last
	else
		return "$(last), $(given)"
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	normaliseBibtexNames(nameLine; collaboration = false)

Normalise one BibTeX name line.
"""
function normaliseBibtexNames(nameLine::AbstractString; collaboration::Bool = false)
	parts = String[]
	for rawName ∈ splitBibtexNames(nameLine)
		name = strip(stripOuterBraces(rawName))
		if isempty(name)
			continue
		end

		if collaboration
			push!(parts, decodeTex(name))
			continue
		end

		formatted = formatBibtexPerson(parseBibtexPerson(name))
		if ! isempty(formatted)
			push!(parts, formatted)
		end
	end

	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	namesToBibtex(people; collaboration = false)

Convert a list of name dictionaries to a BibTeX name line.
"""
function namesToBibtex(people; collaboration::Bool = false)
	parts = String[]
	for person ∈ people
		if collaboration
			name = strip(getString(person, "name"))
			if ! isempty(name)
				push!(parts, name)
			end
			continue
		end

		name = strip(getString(person, "name"))
		if ! isempty(name)
			push!(parts, name)
			continue
		end

		personName = PersonName(strip(getString(person, "first")), strip(getString(person, "middle")), strip(getString(person, "last")), "")

		formatted = formatBibtexPerson(personName)
		if ! isempty(formatted)
			push!(parts, formatted)
		end
	end

	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	bibtexNamesFromPybtexPersons(personsIterable)

Convert a Pybtex persons iterable to one BibTeX name line.
"""
function bibtexNamesFromPybtexPersons(personsIterable)
	parts = String[]
	for person ∈ personsIterable
		# `str(person)` yields the full "Last, suffix, First" form with grouping braces preserved (e.g. `{{\v{S}}ar{\v{c}}evi{\'c}}, N.`).
		# So accent macros that depend on braces survive. This is a single Python round-trip per person.
		nameText = pyconvert(String, pystr(person))
		formatted = formatBibtexPerson(parseBibtexPerson(nameText))
		if ! isempty(formatted)
			push!(parts, formatted)
		end
	end

	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
