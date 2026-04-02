# ----------------------------------------------------------------------------------------------- #
#
@doc """
	BibliographyFormat

Abstract supertype for bibliography serialization formats.
"""
abstract type BibliographyFormat end


struct JsonFormat <: BibliographyFormat end


struct YamlFormat <: BibliographyFormat end


struct BibTeXFormat <: BibliographyFormat end


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
@doc """
	parseBibliographyFormat(name)

Parse a bibliography format name or extension into a dispatchable format object.

# Input
- `name::AbstractString`: format name, such as `"json"`, `"yaml"`, `"yml"`, `"bib"`, or `"bibtex"`.

# Output
- A [`BibliographyFormat`](@ref) singleton corresponding to the requested format.
"""
function parseBibliographyFormat(name::AbstractString)
	formattedName = lowercase(strip(name))
	if formattedName == "json"
		return jsonFormat()
	elseif formattedName == "yaml" || formattedName == "yml"
		return yamlFormat()
	elseif formattedName == "bib" || formattedName == "bibtex"
		return bibTeXFormat()
	else
		throw(ArgumentError("Unsupported format: $(name). Supported: json, yaml, bib"))
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	bibliographyFormat(path)

Infer a bibliography format from a file extension.

# Input
- `path::AbstractString`: file path whose suffix identifies the format.

# Output
- A [`BibliographyFormat`](@ref) singleton inferred from the file extension.
"""
function bibliographyFormat(path::AbstractString)
	lowerPath = lowercase(path)
	if endswith(lowerPath, ".json")
		return jsonFormat()
	elseif endswith(lowerPath, ".yaml") || endswith(lowerPath, ".yml")
		return yamlFormat()
	elseif endswith(lowerPath, ".bib")
		return bibTeXFormat()
	else
		throw(ArgumentError("Cannot infer input format from extension: $(path). Use --from <json|yaml|bib>."))
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readBibliography(format, filename)

Read a bibliography file using the requested format.

# Input
- `format::BibliographyFormat`: format selector.
- `filename::AbstractString`: path to the file to load.

# Output
- A [`ZettelLibrary`](@ref) parsed from `filename`.
"""
readBibliography(::JsonFormat, filename::AbstractString) = readJsonLibrary(filename)
readBibliography(::YamlFormat, filename::AbstractString) = readYamlLibrary(filename)
readBibliography(::BibTeXFormat, filename::AbstractString) = readBibTeX(filename)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeBibliography(format, lib, filename)

Write a bibliography library using the requested format.

# Input
- `format::BibliographyFormat`: output format selector.
- `lib::ZettelLibrary`: bibliography library to serialise.
- `filename::AbstractString`: destination file path.

# Output
- `nothing`.
"""
writeBibliography(::JsonFormat, lib::ZettelLibrary, filename::AbstractString) = writeJsonLibrary(lib, filename)
writeBibliography(::YamlFormat, lib::ZettelLibrary, filename::AbstractString) = writeYamlLibrary(lib, filename)
writeBibliography(::BibTeXFormat, lib::ZettelLibrary, filename::AbstractString) = writeBibTeX(lib, filename)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	convertBibliography(inputPath, outputPath, fromFormat, toFormat)

Convert a bibliography file between supported formats.

# Input
- `inputPath::AbstractString`: source file path.
- `outputPath::AbstractString`: destination file path.
- `fromFormat::BibliographyFormat`: input format selector.
- `toFormat::BibliographyFormat`: output format selector.

# Output
- The `outputPath` string after writing the converted file.
"""
function convertBibliography(inputPath::AbstractString, outputPath::AbstractString, fromFormat::BibliographyFormat, toFormat::BibliographyFormat)
	return _convertBibliography(inputPath, outputPath, fromFormat, toFormat)
end


# ----------------------------------------------------------------------------------------------- #
#
function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::JsonFormat, ::JsonFormat)
	_writeJsonData(_readJsonData(inputPath), outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::YamlFormat, ::YamlFormat)
	_writeYamlData(_readYamlData(inputPath), outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::BibTeXFormat, ::BibTeXFormat)
	writeBibliography(bibTeXFormat(), readBibliography(bibTeXFormat(), inputPath), outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::BibTeXFormat, ::JsonFormat)
	data = _bibTeXToStructuredData(inputPath)
	_writeJsonData(data, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::BibTeXFormat, ::YamlFormat)
	data = _bibTeXToStructuredData(inputPath)
	_writeYamlData(data, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::JsonFormat, ::BibTeXFormat)
	lib = readJsonLibrary(inputPath)
	writeBibTeX(lib, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::JsonFormat, ::YamlFormat)
	data = _readJsonData(inputPath)
	_writeYamlData(data, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::YamlFormat, ::BibTeXFormat)
	lib = readYamlLibrary(inputPath)
	writeBibTeX(lib, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::YamlFormat, ::JsonFormat)
	data = _readYamlData(inputPath)
	_writeJsonData(data, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, fromFormat::BibliographyFormat, toFormat::BibliographyFormat)
	throw(ArgumentError("Unsupported conversion: $(typeof(fromFormat)) -> $(typeof(toFormat))"))
end

# ----------------------------------------------------------------------------------------------- #
#