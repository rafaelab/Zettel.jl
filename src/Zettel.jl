module Zettel

export 
	ZettelEntry,
	ZettelLibrary,
	readJsonLibrary,
	writeJsonLibrary,
	readYamlLibrary,
	writeYamlLibrary,
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
	bibTeXToYaml,
	jsonToBibTeX,
	yamlToBibTeX,
	yamlToJson,
	jsonToYaml,
	findByKey,
	searchEntries,
	filterByField,
	parseAuxFile,
	writeBblFromAux,
	zettelCLI



using Downloads
using JSON3
using YAML
using Pybtex
using OrderedCollections
using Printf
using PythonCall
using HTTP



include("entry.jl")
include("library.jl")
include("formatIO.jl")
include("jsonIO.jl")
include("yamlIO.jl")
include("crossref.jl")
include("bibtex.jl")
include("query.jl")
include("texAux.jl")
include("styles.jl")
include("cli.jl")


end
