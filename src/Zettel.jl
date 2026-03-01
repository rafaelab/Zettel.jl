module Zettel

export
	ZettelEntry,
	ZettelLibrary,
	readJsonLibrary,
	writeJsonLibrary,
	readBibTeX,
	writeBibTeX,
	toBibTeX,
	fromBibTeX,
	fetchFromCrossref,
	getKey,
	getType,
	getField,
	hasField,
	getAuthors,
	getTitle,
	getYear,
	getJournal,
	getDOI,
	getURL,
	getVolume,
	getNumber,
	getPages,
	getAbstract,
	getPublisher,
	getISBN,
	getAllFields

using HTTP
using JSON3
using OrderedCollections
using Printf
using PythonCall
using Pybtex


include("types.jl")
include("json_io.jl")
include("crossref.jl")
include("bibtex.jl")


end # module Zettel
