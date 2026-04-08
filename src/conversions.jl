export
	bibtexToJson,
	jsonToBibtex,
	bibtexToYaml,
	yamlToBibtex,
	yamlToJson,
	jsonToYaml


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	bibtexToJson(inputPath, outputPath)

Convert a BibTeX bibliography file to JSON.
"""
function bibtexToJson(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, BibtexFormat(), JsonFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	jsonToBibtex(inputPath, outputPath)

Convert a JSON bibliography file to BibTeX.
"""
function jsonToBibtex(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, JsonFormat(), BibtexFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	bibTeXToYaml(inputPath, outputPath)

Convert a BibTeX bibliography file to YAML.
"""
function bibtexToYaml(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, BibtexFormat(), YamlFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	yamlToBibTeX(inputPath, outputPath)

Convert a YAML bibliography file to BibTeX.
"""
function yamlToBibtex(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, YamlFormat(), BibtexFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	yamlToJson(inputPath, outputPath)

Convert a YAML bibliography file to JSON.
"""
function yamlToJson(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, YamlFormat(), JsonFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	jsonToYaml(inputPath, outputPath)

Convert a JSON bibliography file to YAML.
"""
function jsonToYaml(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, JsonFormat(), YamlFormat())
end


# ----------------------------------------------------------------------------------------------- #
