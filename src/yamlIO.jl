# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeYamlLibrary(lib, filename)

Serialise a [`ZettelLibrary`](@ref) to a YAML file at `filename`.

# Input
- `lib::ZettelLibrary`: bibliography library to serialise.
- `filename::AbstractString`: destination YAML file.

# Output
- `nothing`.

The file stores each entry as an object with `"key"`, `"type"`, and `"fields"` properties
that mirror the corresponding BibTeX fields.
"""
function writeYamlLibrary(lib::ZettelLibrary, filename::AbstractString)
	records = [_entryToOrderedDict(entry) for entry ∈ values(lib)]
	_writeYamlData(records, filename)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readYamlLibrary(filename)

Read a YAML file and return a [`ZettelLibrary`](@ref).

# Input
- `filename::AbstractString`: path to a YAML bibliography file.

# Output
- A [`ZettelLibrary`](@ref).

This accepts both:
- the list-based library format produced by [`writeYamlLibrary`](@ref)
- the per-key Zettel format produced by [`bibTeXToYaml`](@ref)
"""
function readYamlLibrary(filename::AbstractString)
	isfile(filename) || throw(ArgumentError("Input YAML file not found: $(filename)."))
	data = _readYamlData(filename)
	return _libraryFromParsedData(data, filename, "YAML")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a BibTeX file into YAML while preserving entry type and fields, and structuring author/editor/translator persons as name parts.

# Input
- `inputPath::AbstractString`: source `.bib` file.
- `outputPath::AbstractString`: destination `.yaml` file.

# Output
- The `outputPath` string after writing the converted file.
"""
function bibTeXToYaml(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, bibTeXFormat(), yamlFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a YAML bibliography into JSON.

# Input
- `inputPath::AbstractString`: source `.yaml` or `.yml` file.
- `outputPath::AbstractString`: destination `.json` file.

# Output
- The `outputPath` string after writing the converted file.
"""
function yamlToJson(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, yamlFormat(), jsonFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a JSON bibliography into YAML.

# Input
- `inputPath::AbstractString`: source `.json` file.
- `outputPath::AbstractString`: destination `.yaml` file.

# Output
- The `outputPath` string after writing the converted file.
"""
function jsonToYaml(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, jsonFormat(), yamlFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a YAML bibliography into BibTeX.

# Input
- `inputPath::AbstractString`: source `.yaml` or `.yml` file.
- `outputPath::AbstractString`: destination `.bib` file.

# Output
- The `outputPath` string after writing the converted file.
"""
function yamlToBibTeX(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, yamlFormat(), bibTeXFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_readYamlData(filename)

Read and normalise a YAML bibliography payload.

# Input
- `filename::AbstractString`: path to the YAML file.

# Output
- The parsed and normalised YAML payload.
"""
function _readYamlData(filename::AbstractString)
	if ! isfile(filename) 
		throw(ArgumentError("Input YAML file not found: $(filename)"))
	end

	parsed = try
		YAML.load(read(filename, String))
	catch
		throw(ArgumentError("Input YAML file is not valid YAML: $(filename)"))
	end
	return _normaliseParsedData(parsed)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_writeYamlData(data, filename)

Write normalised bibliography data to a YAML file.

# Input
- `data`: bibliography payload to serialise.
- `filename::AbstractString`: destination YAML file.

# Output
- `nothing`.
"""
function _writeYamlData(data, filename::AbstractString)
	yamlData = _toYamlData(data)
	yamlString = try
		YAML.write(yamlData)
	catch
		throw(ArgumentError("Failed to serialise bibliography to YAML."))
	end
	if ! isempty(yamlString) && yamlString[end] ≠ '\n'
		yamlString *= "\n"
	end
	write(filename, yamlString)
	
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_toYamlData(value)

Convert nested Julia collections into YAML-friendly data structures.

# Input
- `value`: bibliography payload or nested collection.

# Output
- A YAML-serialisable value.
"""
function _toYamlData(value::Any)
	return value
end


@doc """
	_toYamlData(value)

Convert nested Julia collections into YAML-friendly data structures.

# Input
- `value::AbstractDict`: dictionary-like value.

# Output
- An `OrderedDict{String, Any}` with string keys.
"""
function _toYamlData(value::AbstractDict)
	out = OrderedDict{String, Any}()
	for (key, child) ∈ pairs(value)
		out[String(key)] = _toYamlData(child)
	end
	return out
end


@doc """
	_toYamlData(value)

Convert nested Julia collections into YAML-friendly data structures.

# Input
- `value::AbstractVector`: vector-like value.

# Output
- A vector of YAML-serialisable values.
"""
function _toYamlData(value::AbstractVector)
	return [_toYamlData(child) for child ∈ value]
end


# ----------------------------------------------------------------------------------------------- #
