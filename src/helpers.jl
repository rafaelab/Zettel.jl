export
	getFileExtension,
	nonEmptyString,
	stripOuterBraces,
	encodeUriComponent,
	isAsciiUnreserved,
	entryKeyFromNameAndYear,
	getString,
	splitGivenName


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getFileExtension(filename)

Identify the bibliography format of a file based on its extension.

# Input
- `filename::AbstractString`: path to the file whose format is to be identified.

# Output
- A string corresponding to the file's extension, in lowercase and with leading/trailing whitespace removed.
"""
@inline getFileExtension(filename::AbstractString) = lowercase(strip(splitext(filename)[2]))


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	nonEmptyString(value)

Normalise optional string-like values to `nothing` when empty (after trimming).
"""
function nonEmptyString(value)
	if isnothing(value)
		return nothing
	end

	text = strip(String(value))
	if isempty(text)
		return nothing
	end

	return text
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	stripOuterBraces(s)

Remove outer braces from a string, if they are present.
"""
function stripOuterBraces(s::AbstractString)
	t = strip(String(s))
	while startswith(t, "{") && endswith(t, "}")
		# Only strip one layer when the first "{" matches the final "}".
		# This avoids corrupting strings like "{\v{S}}ar{\v{c}}evi{\'c}".
		depth = 0
		wrapsWholeString = true
		i = firstindex(t)
		while i ≤ lastindex(t)
			c = t[i]
			if c == '{'
				depth += 1
			elseif c == '}'
				depth -= 1
				if depth < 0
					wrapsWholeString = false
					break
				end
				if depth == 0 && i < lastindex(t)
					wrapsWholeString = false
					break
				end
			end
			i = nextind(t, i)
		end
		if ! wrapsWholeString || depth ≠ 0
			break
		end

		i = nextind(t, firstindex(t))
		j = prevind(t, lastindex(t))
		if i > j
			return ""
		end
		t = strip(t[i : j])
	end
	return t
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	encodeUriComponent(value)

Percent-encode a string for use in a URI path component.

# Input
- `value::AbstractString`: string to encode.

# Output
- The encoded URI component.
"""
function encodeUriComponent(value::AbstractString)
	io = IOBuffer()

	for b ∈ codeunits(value)
		if isAsciiUnreserved(b)
			write(io, b)
		else
			print(io, '%')
			print(io, uppercase(string(b; base = 16, pad = 2)))
		end
	end

	return String(take!(io))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	isAsciiUnreserved(b)

Return whether a byte is an unreserved ASCII URI character.

# Input
- `b::UInt8`: byte to test.

# Output
- `true` if `b` is unreserved, otherwise `false`.
"""
function isAsciiUnreserved(b::UInt8)
	return 
		(UInt8('A') ≤ b ≤ UInt8('Z')) ||
		(UInt8('a') ≤ b ≤ UInt8('z')) ||
		(UInt8('0') ≤ b ≤ UInt8('9')) ||
		b == UInt8('-') ||
		b == UInt8('.') ||
		b == UInt8('_') ||
		b == UInt8('~')
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	entryKeyFromNameAndYear(name, year)

Build a stable citation key seed from first author/contributor name and publication year.
"""
function entryKeyFromNameAndYear(name::AbstractString, year::AbstractString)
	base = replace(strip(String(name)), r"\s+" => "")
	if isempty(base)
		base = "Unknown"
	end
	return base * (isempty(year) ? "" : year)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getString(obj, key)

Name-part helpers (shared by JSON import and BibTeX→structured conversion).
"""
function getString(obj, key::AbstractString)
	sym = Symbol(key)
	if haskey(obj, sym)
		return String(obj[sym])
	elseif haskey(obj, key)
		return String(obj[key])
	else
		return ""
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	splitGivenName(given)

Split a given-name string into `(first, middle)` parts.
"""
function splitGivenName(given::AbstractString)
	g = strip(given)
	if isempty(g)
		return "", ""
	end
	
	parts = split(g, r"\s+")
	if length(parts) == 1
		return parts[1], ""
	end

	return parts[1], join(parts[2 : end], " ")
end

# ----------------------------------------------------------------------------------------------- #