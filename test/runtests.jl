using Test
using Zettel
using JSON3
using OrderedCollections
using PythonCall: pyconvert
import Pybtex


include("common.jl")
include("crossref.jl")
include("json.jl")
include("yaml.jl")
include("entry.jl")
include("library.jl")
include("aux.jl")
include("query.jl")
include("roundtrip.jl")
include("readout.jl")
include("encoding.jl")
include("cli_convert.jl")
include("cli_paste.jl")
include("cli_doi.jl")
include("cli_query.jl")
include("cli_libupdate.jl")
