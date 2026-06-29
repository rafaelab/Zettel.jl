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
