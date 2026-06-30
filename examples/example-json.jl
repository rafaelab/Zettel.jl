using Zettel



bibPath = joinpath(@__DIR__, "data", "references.bib")
jsonPath = joinpath(@__DIR__, "data", "references.json")
roundtripBibPath = joinpath(@__DIR__, "data", "references_roundtrip.bib")

convertBibliography(bibPath, jsonPath, BibtexFormat(), JsonFormat())
convertBibliography(jsonPath, roundtripBibPath, JsonFormat(), BibtexFormat())

record = fetchCrossrefJson("10.1038/nphys1170")
println(record["DOI"])
