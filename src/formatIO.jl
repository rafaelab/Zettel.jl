export
	readEntry,
	readEntries,
	readBibliography,
	writeBibliography,
	convertBibliography


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readEntry(format, filename)

Read exactly one bibliography entry and return a [`ZettelEntry`](@ref).
"""
readEntry(::JsonFormat, filename::AbstractString) = readJsonEntry(filename)
readEntry(::YamlFormat, filename::AbstractString) = readYamlEntry(filename)
readEntry(::BibtexFormat, filename::AbstractString) = readBibtexEntry(filename)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readEntries(format, filename)

Read one or more bibliography entries and return a [`ZettelLibrary`](@ref).
"""
readEntries(format::BibliographyFormat, filename::AbstractString) = readBibliography(format, filename)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readBibliography(format, filename)

Read a bibliography file into a [`ZettelLibrary`](@ref), selecting the parser with `format`.
"""
readBibliography(::JsonFormat, filename::AbstractString) = readJsonLibrary(filename)
readBibliography(::YamlFormat, filename::AbstractString) = readYamlLibrary(filename)
readBibliography(::BibtexFormat, filename::AbstractString) = readBibtexLibrary(filename)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeBibliography(format, lib, filename)

Write a [`ZettelLibrary`](@ref) to `filename`, selecting the writer with `format`.
"""
writeBibliography(::JsonFormat, lib::ZettelLibrary, filename::AbstractString) = writeJsonLibrary(lib, filename)
writeBibliography(::YamlFormat, lib::ZettelLibrary, filename::AbstractString) = writeYamlLibrary(lib, filename)
writeBibliography(::BibtexFormat, lib::ZettelLibrary, filename::AbstractString) = writeBibtexLibrary(lib, filename)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	convertBibliography(inputPath, outputPath, fromFormat, toFormat)

Convert bibliography data between supported formats.
"""
function convertBibliography(inputPath::AbstractString, outputPath::AbstractString, fromFormat::BibliographyFormat, toFormat::BibliographyFormat)
	@info "Converting bibliography from $(formatDisplayName(fromFormat)) to $(formatDisplayName(toFormat))" inputPath outputPath
	lib = readBibliography(fromFormat, inputPath)
	@info "Loaded $(length(lib)) entries from $(inputPath)"

	writeBibliography(toFormat, lib, outputPath)
	@info "Finished writing $(length(lib)) entries to $(outputPath)"

	return outputPath
end


# ----------------------------------------------------------------------------------------------- #
