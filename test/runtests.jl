using Test
using Zettel
using Pybtex
using PythonCall: pyconvert

@testset "Crossref fetch" begin
payload = """{"status":"ok","message":{"DOI":"10.1000/test","title":["Example"]}}"""
record = fetchCrossrefJson("10.1000/test"; fetcher = _ -> payload)
@test record["DOI"] == "10.1000/test"
@test record["title"][1] == "Example"
end

@testset "BibTeX <-> JSON conversion" begin
mktempdir() do dir
inputBib = joinpath(dir, "input.bib")
outputJson = joinpath(dir, "library.json")
outputBib = joinpath(dir, "output.bib")

write(inputBib, """
@article{doe2024,
author = {Doe, Jane and Roe, John},
title = {A Sample Entry},
journal = {Journal of Testing},
year = {2024},
doi = {10.1000/example}
}
""")

bibTeXToJson(inputBib, outputJson)
jsonToBibTeX(outputJson, outputBib)

original = readBibtexDataBase(inputBib)
rebuilt = readBibtexDataBase(outputBib)
originalEntry = getEntry(original, "doe2024")
rebuiltEntry = getEntry(rebuilt, "doe2024")

for field in getAllFields(originalEntry)
@test hasField(rebuiltEntry, field)
@test pyconvert(String, originalEntry.info.fields[field]) == pyconvert(String, rebuiltEntry.info.fields[field])
end
@test length(rebuiltEntry.info.persons["author"]) == length(originalEntry.info.persons["author"])
end
end
