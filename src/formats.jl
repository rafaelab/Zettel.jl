# ----------------------------------------------------------------------------------------------- #
#
@doc """
	BibliographyFormat

Abstract supertype for bibliography serialization formats.
"""
abstract type BibliographyFormat end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	JsonFormat

Singleton type identifying the JSON bibliography serialization format.
"""
struct JsonFormat <: BibliographyFormat
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	YamlFormat

Singleton type identifying the YAML bibliography serialization format.
"""
struct YamlFormat <: BibliographyFormat
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	BibTeXFormat

Singleton type identifying the BibTeX bibliography serialization format.
"""
struct BibTeXFormat <: BibliographyFormat
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	jsonFormat()

Return the JSON format selector.

# Output
- A [`JsonFormat`](@ref) singleton.
"""
jsonFormat() = JsonFormat()


@doc """
	yamlFormat()

Return the YAML format selector.

# Output
- A [`YamlFormat`](@ref) singleton.
"""
yamlFormat() = YamlFormat()


@doc """
	bibTeXFormat()

Return the BibTeX format selector.

# Output
- A [`BibTeXFormat`](@ref) singleton.
"""
bibTeXFormat() = BibTeXFormat()


# ----------------------------------------------------------------------------------------------- #
#