# ----------------------------------------------------------------------------------------------- #
#
const Maybe = Union{Nothing, T} where T


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_getFileExtension(filename)

Identify the bibliography format of a file based on its extension.

# Input
- `filename::AbstractString`: path to the file whose format is to be identified.

# Output
- A string corresponding to the file's extension, in lowercase and with leading/trailing whitespace removed.
"""
function _getFileExtension(filename::AbstractString)
	return lowercase(strip(splitext(filename)[2]))
end



# ----------------------------------------------------------------------------------------------- #