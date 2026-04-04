using Zettel

# Example: Read a library and print a single entry in BibTeX, YAML, and JSON.
#
# Usage:
#   julia examples/print_entry.jl
#
# This script uses the bundled `sample.json` library by default.

libPath = joinpath(@__DIR__, "sample.json")

if ! isfile(libPath)
	throw(ArgumentError("Library file not found: $(libPath)."))
end

lib = readBibliography(bibliographyFormat(libPath), libPath)

all_keys = collect(keys(lib))
if isempty(all_keys)
	println("Library is empty: $libPath")
	return
end

key = all_keys[1]
entry = lib[key]

@info "BibTeX"
println(entryToString(entry, BibTeXFormat()))

@info "YAML"
println(entryToString(entry, YamlFormat()))

@info "JSON"
println(entryToString(entry, JsonFormat()))
