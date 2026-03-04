using Test
using Zettel
using JSON3
import Pybtex
using OrderedCollections
using PythonCall: pyconvert

include("common.jl")
include("crossref_tests.jl")
include("json_io_tests.jl")
include("entry_tests.jl")
include("library_tests.jl")
include("aux_tests.jl")
include("query_tests.jl")
include("roundtrip_tests.jl")
include("cli_tests.jl")
