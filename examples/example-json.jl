using Zettel



bibPath = joinpath(@__DIR__, "data", "references.bib")
jsonPath = joinpath(@__DIR__, "data", "references.json")
roundtripBibPath = joinpath(@__DIR__, "data", "references_roundtrip.bib")

bibtexToJson(bibPath, jsonPath)
jsonToBibtex(jsonPath, roundtripBibPath)

record = fetchCrossrefJson("10.1038/nphys1170")
println(record["DOI"])
