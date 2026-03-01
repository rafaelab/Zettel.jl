## Zettel.jl – basic usage example
#
# This script demonstrates the core workflow:
#   1. Build a small library programmatically.
#   2. Save it as JSON.
#   3. Save it as BibTeX.
#   4. Reload from both formats.
#   5. Fetch metadata from CrossRef (requires internet access).

using Zettel
using OrderedCollections


# ---------------------------------------------------------------------------
# 1. Create entries manually

article = ZettelEntry(
	"Einstein1905",
	"article",
	OrderedDict{String,String}(
		"author"  => "Einstein, A.",
		"title"   => "Zur Elektrodynamik bewegter Körper",
		"journal" => "Annalen der Physik",
		"year"    => "1905",
		"volume"  => "322",
		"number"  => "10",
		"pages"   => "891-921",
		"doi"     => "10.1002/andp.19053221004",
		"adsurl"  => "https://ui.adsabs.harvard.edu/abs/1905AnP...322..891E",
	),
)

book = ZettelEntry(
	"Misner1973",
	"book",
	OrderedDict{String,String}(
		"author"    => "Misner, Charles W. and Thorne, Kip S. and Wheeler, John A.",
		"title"     => "Gravitation",
		"publisher" => "W. H. Freeman",
		"year"      => "1973",
		"isbn"      => "978-0-7167-0344-0",
	),
)

lib = ZettelLibrary([article, book])
println(lib)


# ---------------------------------------------------------------------------
# 2. Inspect individual entries

println(article)
println("  DOI: ", getDOI(article))
println("  Year: ", getYear(article))


# ---------------------------------------------------------------------------
# 3. Save to JSON and reload

jsonFile = tempname() * ".json"
writeJsonLibrary(lib, jsonFile)
println("\nJSON file written to: $jsonFile")

lib2 = readJsonLibrary(jsonFile)
println("Reloaded from JSON: ", lib2)


# ---------------------------------------------------------------------------
# 4. Save to BibTeX and reload

bibFile = tempname() * ".bib"
writeBibTeX(lib, bibFile)
println("BibTeX file written to: $bibFile")

lib3 = readBibTeX(bibFile)
println("Reloaded from BibTeX: ", lib3)


# ---------------------------------------------------------------------------
# 5. Fetch from CrossRef (requires internet access)
#
# Uncomment the lines below when running with network access.

# doi = "10.1002/andp.19053221004"
# entry = fetchFromCrossref(doi)
# println("\nFetched from CrossRef:")
# println(entry)
