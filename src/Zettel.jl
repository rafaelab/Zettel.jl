module Zettel

using Downloads
using JSON3
using Pybtex
using OrderedCollections
using Printf
using PythonCall
using HTTP

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
	getAllFields,
	fetchCrossrefJson,
	saveCrossrefJson,
	crossrefJsonToZettelJson,
	bibTeXToJson,
	jsonToBibTeX

	

include("entry.jl")
include("library.jl")
include("jsonIO.jl")
include("crossref.jl")
include("bibtex.jl")
include("query.jl")


end
