module Zettel

export
	ZettelEntry,
	ZettelLibrary,
	BibliographyFormat,
	BibTeXFormat,
	JsonFormat,
	YamlFormat,
	jsonFormat,
	yamlFormat,
	bibTeXFormat,
	parseBibliographyFormat,
	bibliographyFormat,
	readBibliography,
	writeBibliography,
	convertBibliography,
	readJsonLibrary,
	writeJsonLibrary,
	readYamlLibrary,
	writeYamlLibrary,
	readBibTeXLibrary,
	writeBibTeXLibrary,
	toBibTeX,
	fromBibTeX,
	fetchFromCrossref,
	fetchFromDataCite,
	fetchFromDoiSource,
	doiSources,
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
	loadLibrary,
	saveLibrary,
	entryToString,
	entryFromString,
	decodeTex,
	encodeTex,
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



include("common.jl")
include("formats.jl")
include("entry.jl")
include("encoding.jl")
include("library.jl")
include("formatIO.jl")
include("json.jl")
include("yaml.jl")
include("crossref.jl")
include("bibtex.jl")
include("query.jl")
include("texAux.jl")
include("styles.jl")
include("cli.jl")


end
