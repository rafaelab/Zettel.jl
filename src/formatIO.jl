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
	n = lowercase(strip(name))
	if n == "json"
		return JsonFormat()
	elseif n ∈ ("yaml", "yml")
		return YamlFormat()
	elseif n ∈ ("bib", "bibtex")
		return BibTeXFormat()
	else
		throw(ArgumentError("Unsupported format: $(name). Supported: json, yaml, bib"))
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
readBibliography(::BibTeXFormat, filename::AbstractString) = readBibTeXLibrary(filename)


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
writeBibliography(::BibTeXFormat, lib::ZettelLibrary, filename::AbstractString) = writeBibTeXLibrary(lib, filename)


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
	writeBibTeXLibrary(lib, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::JsonFormat, ::YamlFormat)
	data = _readJsonData(inputPath)
	_writeYamlData(data, outputPath)
	return outputPath
end


function _convertBibliography(inputPath::AbstractString, outputPath::AbstractString, ::YamlFormat, ::BibTeXFormat)
	lib = readYamlLibrary(inputPath)
	writeBibTeXLibrary(lib, outputPath)
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