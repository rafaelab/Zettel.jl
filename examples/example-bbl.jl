# ----------------------------------------------------------------------------------------------- #
# Extract from a master .bib only the references actually used in a compiled .bbl.
#
# `writeBibFromBbl` reads the cited bibkeys from a `.bbl` file (the `\bibitem{...}`
# commands), looks each one up in a master library, and writes a new file containing
# only the used keys (in citation order). The output format is inferred from the
# extension, so `.bib`, `.json`, `.yaml`/`.yml` all work.
# ----------------------------------------------------------------------------------------------- #

using Zettel

const masterLibrary = joinpath(@__DIR__, "data", "references.bib")
const bblFile = joinpath(@__DIR__, "data", "sample.bbl")
const outputFile = joinpath(@__DIR__, "tmp", "sample_bbl2.bib")

mkpath(dirname(outputFile))

result = writeBibFromBbl(bblFile, masterLibrary, outputFile)

println("Extracted $(length(result.present)) entries to $(outputFile).")
if ! isempty(result.absent)
	println("Missing bibkeys: ", join(result.absent, ", "))
end
