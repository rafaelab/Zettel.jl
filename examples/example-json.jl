using Zettel



bibtexToJson("references.bib", "references.json")
jsonToBibtex("references.json", "references_roundtrip.bib")

record = fetchCrossrefJson("10.1038/nphys1170")
println(record["DOI"])
