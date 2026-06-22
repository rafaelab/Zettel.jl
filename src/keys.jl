# ----------------------------------------------------------------------------------------------- #
#
# This is the pattern of the generated citation keys, which consist of:
#   . a lowercase author/collaboration token,
#   . a 4-digit year,
#   . a lowercase letter suffix (e.g. `alvesbatista2026a`)
const entryKeyPattern = r"^[a-z]+[0-9]{4}[a-z]$"

# ----------------------------------------------------------------------------------------------- #
#
const collaborationWords = (
	"collaboration",
	"collaborations",
	"consortium",
	"consortia",
	"team",
	"experiment",
	"project",
	"group",
	""
)

const knownCollabs = Dict(		
	"argo-ybj" => "argoybj",
	"baikal-gvd" => "baikalgvd",
	"chime-frb" => "chimefrb",
	"eas-top" => "eastop",
	"fermi-lat" => "fermi",
	"fermi large area telescope" => "fermi",
	"jem-euso" => "jemeuso",
	"ligo scientific" => "ligo",
	"pierre auger" => "auger",
	"rno-g" => "rnog",
	"super-kamiokande" => "superkamiokande",
	"telescope array" => "ta",
	"tibet as\$\\gamma\$" => "tibet",
	"tpc/two-gamma" => "tpctwogamma",
	"virgo" => "virgo",
)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	cleanKeyToken(text)

Clean a string to be used as part of a generated citation key:
- Unicode normalization (NFD) and removal of diacritics
- Lowercasing
- Removal of non-alphabetic characters
If the resulting token is empty, return "entry".
"""
function cleanKeyToken(text::AbstractString)
	token = strip(String(text))
	token = replace(Base.Unicode.normalize(token, :NFD), r"\p{M}" => "")
	token = lowercase(token)
	token = replace(token, r"[^a-z]" => "")
	return isempty(token) ? "entry" : token
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	yearTokenForGeneratedKey(fields)

Extract a 4-digit year from the entry fields for use in generated keys.
Throws an error if no valid year is found.
"""
function yearTokenForGeneratedKey(fields::AbstractDict{String, String})
	yearText = get(fields, "year", "")
	m = match(r"\d{4}", yearText)
	if isnothing(m)
		throw(ArgumentError("Entry must include a 4-digit year to generate a citation key."))
	end
	return m.match
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	authorTokenForGeneratedKey(fields)

Extract an author-based token for generated keys:
- If `author` field is present, use the last name of the first author.
- If `author` is empty or missing, return "entry".
The token is cleaned to contain only lowercase letters.
"""
function authorTokenForGeneratedKey(fields::AbstractDict{String, String})
	author = get(fields, "author", "")
	if isempty(strip(author))
		return "entry"
	end

	parts = splitBibtexNames(author)
	firstPerson = isempty(parts) ? author : parts[1]
	parsed = parseBibtexPerson(firstPerson)
	last = strip(parsed.lastName)
	if isempty(last)
		last = strip(decodeTex(stripOuterBraces(firstPerson)))
	end

	return cleanKeyToken(last)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	collaborationTokenForGeneratedKey(fields)

Extract a collaboration-based token for generated keys:
- If `collaboration` field is present and non-empty, attempt to derive a token from it.
- Recognise common collaborations (e.g. "Pierre Auger Collaboration" → "auger").
- For other collaborations, use a cleaned version of the first word or initials.
- If `collaboration` is empty or missing, return `nothing`.
The token is cleaned to contain only lowercase letters and digits.
"""
function collaborationTokenForGeneratedKey(fields::AbstractDict{String, String})
	collaboration = get(fields, "collaboration", "")
	if isempty(strip(collaboration))
		return nothing, ""
	end

	parts = splitBibtexNames(collaboration)
	firstCollaboration = isempty(parts) ? collaboration : parts[1]
	displayName = strip(decodeTex(stripOuterBraces(firstCollaboration)))

	normalised = lowercase(displayName)
	normalised = replace(Base.Unicode.normalize(normalised, :NFD), r"\p{M}" => "")
	normalised = replace(normalised, r"[^a-z0-9 ]+" => " ")
	normalised = replace(normalised, r"\s+" => " ")
	normalised = strip(normalised)

	for (name, token) ∈ knownCollabs
		if normalised == name ||
		   startswith(normalised, name * " ") ||
		   startswith(normalised, name * " collaboration") ||
		   startswith(normalised, name * " collaborations")
			return token, displayName
		end
	end

	stopwords = Set(collaborationWords ∪ ("the",))
	tokens = split(normalised)
	filtered = [t for t ∈ tokens if ! (t ∈ stopwords)]
	if isempty(filtered)
		filtered = tokens
	end

	if isempty(filtered)
		return "collab", displayName
	elseif length(filtered) == 1
		return cleanKeyToken(filtered[1]), displayName
	else
		initials = String([t[1] for t ∈ filtered if ! isempty(t)])
		initials = cleanKeyToken(initials)
		return isempty(initials) ? cleanKeyToken(filtered[end]) : initials, displayName
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	nextAvailableGeneratedKey(base, year, existing)

Generate a citation key of the form `base + year + suffix`, where `suffix` is a lowercase letter from `a` to `z`.
The function checks for existing keys in the `existing` set and returns the first available key.
Throws an error if all suffixes are taken.
"""
function nextAvailableGeneratedKey(base::AbstractString, year::AbstractString, existing::Set{String})
	for suffix ∈ 'a':'z'
		key = string(base, year, suffix)
		if ! (key ∈ existing)
			return key
		end
	end
	throw(ArgumentError("No available key suffix in [a-z] for base='$(base)' and year='$(year)'."))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	validGeneratedKeyPattern(key)

Check if a citation key matches the expected pattern for generated keys: lowercase letters followed by a 4-digit year and a lowercase letter (e.g. `smith2024a`).
Returns `true` if the key matches the pattern, `false` otherwise.
"""
function validGeneratedKeyPattern(key::AbstractString)
	return occursin(entryKeyPattern, strip(String(key)))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	shouldUseCollaborationForGeneratedKey(fields)

Decide whether the collaboration token should be used for key generation.
Rules:
- requires a non-empty `collaboration` field;
- when `onbehalf` exists and is truthy, author surname takes precedence.
"""
function shouldUseCollaborationForGeneratedKey(fields::AbstractDict{String, String})
	collaboration = get(fields, "collaboration", "")
	if isempty(strip(collaboration))
		return false
	end
	if ! haskey(fields, "onbehalf")
		return true
	end
	return ! _fieldIsTrue(get(fields, "onbehalf", ""))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	keyFromFileField(fields)

Extract a key candidate from the `file` field (if present), using the basename of the first `.pdf` or `.djvu` attachment path.
Returns `nothing` when no suitable attachment is found.
"""
function keyFromFileField(fields::AbstractDict{String, String})
	if ! haskey(fields, "file")
		return nothing
	end
	fileField = strip(decodeTex(stripOuterBraces(get(fields, "file", ""))))
	if isempty(fileField)
		return nothing
	end

	for attachment in split(fileField, ';')
		chunk = strip(attachment)
		isempty(chunk) && continue

		candidatePath = nothing
		for token in split(chunk, ':')
			text = strip(token)
			if occursin(r"\.(pdf|djvu)$"i, text)
				candidatePath = text
				break
			end
		end
		if isnothing(candidatePath)
			m = match(r"([^:;]+?\.(?:pdf|djvu))"i, chunk)
			if ! isnothing(m)
				candidatePath = m.captures[1]
			end
		end
		if isnothing(candidatePath)
			continue
		end

		stem = strip(splitext(basename(String(candidatePath)))[1])
		if ! isempty(stem)
			return String(stem)
		end
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	matchingKeyFiles(key, libraryPath; fileDir = nothing)

Look for files matching `key` (`.pdf` or `.djvu`) in:
- the library directory;
- `fileDir` if provided, otherwise `<libraryDir>/files`;
- and each of those with an additional first-letter subdirectory.
Returns existing file paths.
"""
function matchingKeyFiles(key::AbstractString, libraryPath::AbstractString; fileDir = nothing)
	keyText = strip(String(key))
	if isempty(keyText)
		return String[]
	end

	libraryDir = dirname(abspath(libraryPath))
	roots = String[libraryDir]
	searchDir = isnothing(fileDir) ? joinpath(libraryDir, "files") : strip(String(fileDir))
	if ! isempty(searchDir)
		push!(roots, abspath(searchDir))
	end

	firstLetter = lowercase(string(keyText[firstindex(keyText)]))
	extensions = (".pdf", ".djvu")

	seen = Set{String}()
	matches = String[]
	for root in roots
		rootPath = normpath(root)
		candidates = String[]
		for ext in extensions
			push!(candidates, joinpath(rootPath, keyText * ext))
			push!(candidates, joinpath(rootPath, firstLetter, keyText * ext))
		end

		for path in candidates
			normalised = normpath(path)
			if normalised ∈ seen
				continue
			end
			push!(seen, normalised)
			if isfile(normalised)
				push!(matches, normalised)
			end
		end
	end

	sort!(matches)
	return matches
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_fieldIsTrue(value)

Internal helper to parse truthy `onbehalf` values.
"""
function _fieldIsTrue(value::AbstractString)
	text = lowercase(strip(decodeTex(stripOuterBraces(value))))
	return text ∈ ("1", "true", "t", "yes", "y", "on")
end

# ----------------------------------------------------------------------------------------------- #
