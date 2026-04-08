export
	DoiSource,
	CrossRefSource,
	DataCiteSource,
	doiSources,
	fetchFromDoiSource,
	fetchFromCrossref,
	fetchFromDataCite,
	fetchCrossrefJson,
	saveCrossrefJson,
	crossrefJsonToZettelJson


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	DoiSource

Abstract supertype for DOI metadata source selectors used by [`fetchFromDoiSource`](@ref).
"""
abstract type DoiSource end
struct CrossRefSource <: DoiSource end
struct DataCiteSource <: DoiSource end


const doiSourcesList = (
	"crossref",
	"datacite",
	# "ads",
	# "inspirehep",
)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	doiSources()

Return the list of supported DOI metadata sources for [`fetchFromDoiSource`](@ref).
"""
doiSources() = collect(doiSourcesList)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fetchFromDoiSource(doi, source; kwargs...)

Fetch a [`ZettelEntry`](@ref) for a DOI from the given `source`.
Supported sources are listed by [`doiSources`](@ref).

The `source` argument may be a [`DoiSource`](@ref) singleton, or a string such as
`"crossref"` or `"datacite"`.
"""
function fetchFromDoiSource(doi::AbstractString, source::AbstractString; kwargs...)
	s = lowercase(strip(source))
	if s == "crossref"
		return fetchFromDoiSource(doi, CrossRefSource(); kwargs...)
	elseif s == "datacite"
		return fetchFromDoiSource(doi, DataCiteSource(); kwargs...)
	end
	throw(ArgumentError("Unsupported DOI source: $(source). Supported: $(join(doiSources(), ", "))"))
end

function fetchFromDoiSource(doi::AbstractString; source::AbstractString = "crossref", kwargs...)
	return fetchFromDoiSource(doi, source; kwargs...)
end

function fetchFromDoiSource(doi::AbstractString, ::CrossRefSource; kwargs...)
	return fetchFromCrossref(doi; kwargs...)
end

function fetchFromDoiSource(doi::AbstractString, ::DataCiteSource; kwargs...)
	return fetchFromDataCite(doi; kwargs...)
end


# ----------------------------------------------------------------------------------------------- #
#
include("dataSources/crossref.jl")
include("dataSources/datacite.jl")


# ----------------------------------------------------------------------------------------------- #
