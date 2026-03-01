using Zettel

bibTeXToJson("references.bib", "references.json")
jsonToBibTeX("references.json", "references_roundtrip.bib")

record = fetchCrossrefJson("10.1038/nphys1170")
println(record["DOI"])
