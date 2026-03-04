const TEST_REF =  """
@article{doe2024,
author = {Doe, Jane and Roe, John},
title = {A Sample Entry},
journal = {Journal of Testing},
year = {2024},
doi = {10.1000/example}
}
"""

# Helper: build a simple article entry for reuse across tests
function _sampleArticle()
	fields = OrderedDict{String, String}(
		"author"  => "Einstein, A.",
		"title"   => "Zur Elektrodynamik bewegter Körper",
		"journal" => "Annalen der Physik",
		"year"    => "1905",
		"volume"  => "322",
		"number"  => "10",
		"pages"   => "891-921",
		"doi"     => "10.1002/andp.19053221004",
	)
	return ZettelEntry("Einstein1905", "article", fields)
end

function _sampleBook()
	fields = OrderedDict{String, String}(
		"author"    => "Misner, Charles W. and Thorne, Kip S. and Wheeler, John A.",
		"title"     => "Gravitation",
		"publisher" => "W. H. Freeman",
		"year"      => "1973",
		"isbn"      => "978-0-7167-0344-0",
	)
	return ZettelEntry("Misner1973", "book", fields)
end
