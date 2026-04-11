export
	BibliographyFormat,
	JsonFormat,
	YamlFormat,
	BibtexFormat,
	bibliographyFormat,
	identifyBibliographyFormat,
	parseBibliographyFormat


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	BibliographyFormat

Abstract supertype for bibliography serialisation formats.
Use the concrete singletons [`JsonFormat`](@ref), [`YamlFormat`](@ref), and [`BibtexFormat`](@ref)
to select the desired format for dispatch.
"""
abstract type BibliographyFormat end



# ----------------------------------------------------------------------------------------------- #
#
@doc """
	BibtexFormat

Singleton type identifying the BibTeX bibliography serialisation format.
"""
struct BibtexFormat <: BibliographyFormat
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	JsonFormat

Singleton type identifying the JSON bibliography serialisation format.
"""
struct JsonFormat <: BibliographyFormat
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	YamlFormat

Singleton type identifying the YAML bibliography serialisation format.
"""
struct YamlFormat <: BibliographyFormat
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fileExtensionFromFormat(format)

Get the canonical file extension for a bibliography format.
"""
fileExtensionFromFormat(::Type{BibtexFormat}) = "bib"
fileExtensionFromFormat(::Type{JsonFormat}) = "json"
fileExtensionFromFormat(::Type{YamlFormat}) = "yaml"
fileExtensionFromFormat(format::BibliographyFormat) = getFileExtension(typeof(format))


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	identifyBibliographyFormat(path)

Infer a bibliography format from a file extension.
"""
function identifyBibliographyFormat(path::AbstractString)
	ext = getFileExtension(path)
	if ext == ".json"
		return JsonFormat()
	elseif ext ∈ (".yaml", ".yml")
		return YamlFormat()
	elseif ext ∈ (".bib", ".bibtex")
		return BibtexFormat()
	else
		throw(ArgumentError("Cannot infer format from extension: $(path)."))
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	bibliographyFormat(path)

Alias of [`identifyBibliographyFormat`](@ref).
"""
bibliographyFormat(path::AbstractString) = identifyBibliographyFormat(path)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	parseBibliographyFormat(name)

Parse a format name (`json`, `yaml`/`yml`, `bib`/`bibtex`) into a
[`BibliographyFormat`](@ref) singleton.
"""
function parseBibliographyFormat(name::AbstractString)
	value = lowercase(strip(name))
	if value == "json"
		return JsonFormat()
	elseif value ∈ ("yaml", "yml")
		return YamlFormat()
	elseif value ∈ ("bib", "bibtex")
		return BibtexFormat()
	else
		throw(ArgumentError("Unsupported bibliography format: $(name)."))
	end
end


# ----------------------------------------------------------------------------------------------- #
