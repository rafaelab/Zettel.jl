export
	SimilarityConfig,
	similarityScores,
	totalSimilarityScore,
	verySimilarEntry,
	findVerySimilarEntry,
	similarityReport


# ----------------------------------------------------------------------------------------------- #
#
const _similarityWeights = (
	author = 0.22,
	key = 0.18,
	title = 0.25,
	venue = 0.20,
	volumePages = 0.15,
)
const _defaultSimilarityFields = (
	"title", 
	"journal", 
	"booktitle"
)
const _defaultsSimilarityConfig = (
	authorThreshold = 0.95,
	keyThreshold = 0.95,
	titleThreshold = 0.95,
	venueThreshold = 0.95,
	volumePagesThreshold = 0.95,
	totalThreshold = 0.95,
	otherThreshold = 0.95,
	contingent = false,
	fields = _defaultSimilarityFields,
	fieldScorers = Dict{String, Function}(),
	scoreWeights = _similarityWeights,
)

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	SimilarityConfig{T <: Real, F, W, S}

Bundles every parameter controlling the duplicate-detection pipeline so that callers can build one config object and reuse it across many comparisons.
Note that the order is important for `contingent`: (`author → title → year → booktitle → journal → volume → pages → others`).

# Fields
- `authorThreshold` [`T`]: minimum author-similarity score to consider a match
- `keyThreshold` [`T`]: minimum citation-key similarity score to consider a match
- `titleThreshold` [`T`]: minimum title similarity score to consider a match
- `venueThreshold` [`T`]: minimum venue (journal or booktitle) similarity score
- `volumePagesThreshold` [`T`]: minimum combined volume+pages similarity score
- `totalThreshold` [`T`]: minimum weighted-total score for a positive decision
- `otherThreshold` [`T`]: minimum score for any field not explicitly checked above
- `contingent` [`Bool`]: when `true`, checks are applied in a strict ordered chain; failing any step returns `nothing` immediately
- `fields`[`F`]: field names scored for textual similarity
- `fieldScorers` [`S`]: per-field scoring overrides (field name → `Function(a,b) -> Float64`)
- `scoreWeights` [`W`]: named-tuple weights keyed `(author, key, title, venue, volumePages)`

# Constructor
Keyword constructor for [`SimilarityConfig`](@ref) with sensible defaults (all thresholds `0.95`, non-contingent, standard fields and weights).
All threshold arguments are promoted to a common floating-point type.
- `SimilarityConfig(; authorThreshold::Real = 0.95, keyThreshold::Real = 0.95, titleThreshold::Real = 0.95, venueThreshold::Real = 0.95, volumePagesThreshold::Real = 0.95, totalThreshold::Real = 0.95, contingent::Bool = false, otherThreshold::Real = titleThreshold, fields = _defaultSimilarityFields, fieldScorers = Dict{String, Function}(), scoreWeights = _similarityWeights)`
"""
struct SimilarityConfig{T <: Real, F, W, S}
	authorThreshold::T
	keyThreshold::T
	titleThreshold::T
	venueThreshold::T
	volumePagesThreshold::T
	totalThreshold::T
	otherThreshold::T
	contingent::Bool
	fields::F
	fieldScorers::S
	scoreWeights::W
end


SimilarityConfig(; kwargs...) = begin
	args = merge(_defaultsSimilarityConfig, kwargs)
	if ! haskey(kwargs, :otherThreshold)
		args = merge(args, (otherThreshold = args.titleThreshold,))
	end

	thresholdFields = (:authorThreshold, :keyThreshold, :titleThreshold, :venueThreshold, :volumePagesThreshold, :totalThreshold, :otherThreshold)
	T = promote_type((typeof(float(args[field])) for field ∈ thresholdFields)...)
	thresholdValues = NamedTuple{thresholdFields}(T(args[field]) for field ∈ thresholdFields)
	args = merge(args, thresholdValues)

	return SimilarityConfig{T, typeof(args.fields), typeof(args.scoreWeights), typeof(args.fieldScorers)}(args...)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	scoreByField(field, left, right, fieldScorers)

Score one field using a caller-supplied scorer, a built-in scorer for `volume` or `pages`, or `stringSimilarityScore` as a fallback.
"""
function scoreByField(field::AbstractString, left::AbstractString, right::AbstractString, fieldScorers::AbstractDict{String, Function})
	name = lowercase(strip(field))
	if haskey(fieldScorers, name)
		return fieldScorers[name](left, right)
	end
	if name == "volume"
		return volumeSimilarityScore(left, right)
	end
	if name == "pages"
		return pagesSimilarityScore(left, right)
	end
	return stringSimilarityScore(left, right)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	normalisePagesText(pages)

Normalise page text for similarity comparison (lowercase, collapse separators).
"""
function normalisePagesText(pages::AbstractString)
	text = strip(lowercase(String(pages)))
	text = replace(text, "–" => "-", "—" => "-", "--" => "-")
	text = replace(text, r"[^0-9a-z\-]+" => "")
	return text
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	parsePageRange(text)

Parse a normalised page string into `(start, end)` when possible, or `nothing`.
"""
function parsePageRange(text::AbstractString)
	m = match(r"([0-9]+)\-([0-9]+)", text)
	if ! isnothing(m)
		a = tryparse(Int, m.captures[1])
		b = tryparse(Int, m.captures[2])
		if ! isnothing(a) && ! isnothing(b)
			return (min(a, b), max(a, b))
		end
	end

	n = match(r"([0-9]+)", text)
	if ! isnothing(n)
		v = tryparse(Int, n.captures[1])
		if ! isnothing(v)
			return (v, v)
		end
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	volumeSimilarityScore(left, right)

Compare volume identifiers, preferring numeric closeness when both are numeric.
"""
function volumeSimilarityScore(v1::AbstractString, v2::AbstractString)
	a = strip(v1)
	b = strip(v2)
	if isempty(a) || isempty(b)
		return 0.
	end
	if lowercase(a) == lowercase(b)
		return 1.
	end

	ai = tryparse(Int, replace(a, r"[^0-9]" => ""))
	bi = tryparse(Int, replace(b, r"[^0-9]" => ""))
	if ! isnothing(ai) && ! isnothing(bi) && max(ai, bi) > 0
		diff = abs(ai - bi)
		return max(0., 1. - (diff / max(ai, bi)))
	end

	return stringSimilarityScore(a, b)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	pagesSimilarityScore(left, right)

Compare page spans using exact match, numeric range endpoints, and text fallback.
"""
function pagesSimilarityScore(p1::AbstractString, p2::AbstractString)
	a = normalisePagesText(p1)
	b = normalisePagesText(p2)
	if isempty(a) || isempty(b)
		return 0.
	end
	if a == b
		return 1.
	end

	rangeA = parsePageRange(a)
	rangeB = parsePageRange(b)
	if ! isnothing(rangeA) && ! isnothing(rangeB)
		aStart, aEnd = rangeA
		bStart, bEnd = rangeB
		startScore = 1. - min(1., abs(aStart - bStart) / max(1, max(aStart, bStart)))
		endScore = 1. - min(1., abs(aEnd   - bEnd  ) / max(1, max(aEnd, bEnd)))
		spanA = max(1, aEnd - aStart + 1)
		spanB = max(1, bEnd - bStart + 1)
		spanScore = 1. - min(1., abs(spanA - spanB) / max(spanA, spanB))
		return (startScore + endScore + spanScore) / 3
	end

	return stringSimilarityScore(a, b)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	volumePagesSimilarityScore(volumeLeft, volumeRight, pagesLeft, pagesRight)

Combine volume and pages similarity, requiring at least one comparable component.
"""
function volumePagesSimilarityScore(volume1::AbstractString, volume2::AbstractString, pages1::AbstractString, pages2::AbstractString)
	vCompared = ! isempty(strip(volume1)) && ! isempty(strip(volume2))
	pCompared = ! isempty(strip(pages1))  && ! isempty(strip(pages2))

	if ! vCompared && ! pCompared
		return 0.
	end
	if vCompared && pCompared
		return (volumeSimilarityScore(volume1, volume2) + pagesSimilarityScore(pages1, pages2)) / 2
	end

	return vCompared ? volumeSimilarityScore(volume1, volume2) : pagesSimilarityScore(pages1, pages2)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	stringSimilarityScore(left, right)

Normalised Levenshtein similarity in `[0, 1]` after light text normalisation.
"""
function stringSimilarityScore(v1::AbstractString, v2::AbstractString)
	a = _normalisedSimilarityText(v1)
	b = _normalisedSimilarityText(v2)
	if isempty(a) && isempty(b)
		return 1.
	end
	if isempty(a) || isempty(b)
		return 0.
	end

	dist  = levenshteinDistance(collect(a), collect(b))
	scale = max(length(a), length(b))

	return scale == 0 ? 1. : 1 - (dist / scale)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	keyTokenFromEntryKey(key)

Extract a normalised token from a citation key by stripping a trailing 4-digit year + optional letter.
"""
function keyTokenFromEntryKey(key::AbstractString)
	raw   = strip(String(key))
	token = replace(raw, r"\d{4}[a-zA-Z]$" => "")
	token = isempty(token) ? raw : token
	token = _normalisedSimilarityText(token)
	token = replace(token, r"\s+" => "")
	return token
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	authorSurnameToken(fields)

Extract the first author's surname as a normalised token for similarity comparison.
"""
function authorSurnameToken(fields::AbstractDict{String, String})
	author = get(fields, "author", "")
	if isempty(strip(author))
		return ""
	end

	parts = splitBibtexNames(author)
	firstPerson = isempty(parts) ? author : parts[1]
	parsed = parseBibtexPerson(firstPerson)
	last = strip(parsed.lastName)
	if isempty(last)
		last = strip(decodeTex(stripOuterBraces(firstPerson)))
	end

	return cleanKeyToken(last)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	similarityScores(candidate, existing, config)
	similarityScores(candidate, existing; fields, fieldScorers, scoreWeights)

Compute detailed similarity components and a weighted total score in `[0, 1]`.
Keyword-argument form of [`similarityScores`](@ref). Builds a [`SimilarityConfig`](@ref) from `fields`, `fieldScorers`, and `scoreWeights` and delegates to the primary method.

The returned named tuple includes:
- arbitrary per-field scores from `config.fields`;
- `author`, `key`, `title`, and venue (`journal` or `booktitle`) scores;
- `volume`, `pages`, and combined `volumePages` scores;
- exact `year` agreement score;
- weighted `totalScore`.
"""
function similarityScores(candidate::ZettelEntry, existing::ZettelEntry, config::SimilarityConfig)
	fieldScores = OrderedDict{String, Float64}()

	for field ∈ config.fields
		candidateValue = get(candidate.fields, field, "")
		existingValue  = get(existing.fields,  field, "")
		if isempty(strip(candidateValue)) || isempty(strip(existingValue))
			continue
		end
		fieldScores[field] = scoreByField(field, candidateValue, existingValue, config.fieldScorers)
	end

	candidateAuthor = authorSurnameToken(candidate.fields)
	existingAuthor = authorSurnameToken(existing.fields)
	authorScore = (isempty(candidateAuthor) || isempty(existingAuthor)) ? 0. : stringSimilarityScore(candidateAuthor, existingAuthor)

	candidateKeyToken = keyTokenFromEntryKey(candidate.key)
	existingKeyToken = keyTokenFromEntryKey(existing.key)
	keyScore = (isempty(candidateKeyToken) || isempty(existingKeyToken)) ? 0. : stringSimilarityScore(candidateKeyToken, existingKeyToken)

	titleScore = get(fieldScores, "title", 0.0)
	journalScore = get(fieldScores, "journal", 0.0)
	booktitleScore = get(fieldScores, "booktitle", 0.0)
	venueScore = max(journalScore, booktitleScore)

	candidateYear = strip(get(candidate.fields, "year", ""))
	existingYear = strip(get(existing.fields,  "year", ""))
	yearScore = (! isempty(candidateYear) && ! isempty(existingYear) && candidateYear == existingYear) ? 1.0 : 0.0

	candidateVolume = strip(get(candidate.fields, "volume", ""))
	existingVolume = strip(get(existing.fields,  "volume", ""))
	candidatePages = get(candidate.fields, "pages", "")
	existingPages = get(existing.fields,  "pages", "")
	volumeScore = volumeSimilarityScore(candidateVolume, existingVolume)
	pagesScore = pagesSimilarityScore(candidatePages, existingPages)
	volumePagesScore = volumePagesSimilarityScore(candidateVolume, existingVolume, candidatePages, existingPages)
	fieldScores["volume"] = volumeScore
	fieldScores["pages"] = pagesScore

	weights = _normalisedSimilarityWeights(config.scoreWeights)
	totalScore =  weights.author * authorScore + weights.key * keyScore + weights.title * titleScore + weights.venue * venueScore + weights.volumePages * volumePagesScore

	return (
		fieldScores = fieldScores,
		authorScore = authorScore,
		keyScore = keyScore,
		titleScore = titleScore,
		journalScore = journalScore,
		booktitleScore = booktitleScore,
		venueScore = venueScore,
		yearScore = yearScore,
		volumeScore = volumeScore,
		pagesScore = pagesScore,
		volumePagesScore = volumePagesScore,
		totalScore = totalScore,
		candidateAuthor = candidateAuthor,
		existingAuthor = existingAuthor,
		year = isempty(candidateYear) ? existingYear : candidateYear,
		volume = isempty(candidateVolume) ? existingVolume : candidateVolume,
	)
end

function similarityScores(candidate::ZettelEntry, existing::ZettelEntry; kwargs...)
	config = SimilarityConfig(; kwargs...)
	return similarityScores(candidate, existing, config)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_normalisedSimilarityText(text)

Normalise free text for Levenshtein-based similarity: strip TeX, decompose accents,
lowercase, keep only `[a-z0-9]` tokens.
"""
function _normalisedSimilarityText(text::AbstractString)
	s = strip(decodeTex(stripOuterBraces(text)))
	s = replace(Base.Unicode.normalize(s, :NFD), r"\p{M}" => "")
	s = lowercase(s)
	s = replace(s, r"[^a-z0-9]+" => " ")
	s = replace(s, r"\s+" => " ")
	return strip(s)
end


@doc """
	_normalisedSimilarityWeights(scoreWeights)

Normalise a named-tuple of similarity weights so that they sum to `1.0`.
"""
function _normalisedSimilarityWeights(scoreWeights)
	requiredKeys = (:author, :key, :title, :venue, :volumePages)
	weights = Dict{Symbol, Float64}()
	for key ∈ requiredKeys
		if ! haskey(scoreWeights, key)
			throw(ArgumentError("Missing similarity weight: $(key)."))
		end
		value = Float64(scoreWeights[key])
		if value < 0
			throw(DomainError("Similarity weights must be non-negative."))
		end
		weights[key] = value
	end

	normalisation = sum(values(weights))
	if normalisation ≤ 0
		throw(ArgumentError("At least one similarity weight must be positive."))
	end

	return (
		author = weights[:author] / normalisation,
		key = weights[:key] / normalisation,
		title = weights[:title] / normalisation,
		venue = weights[:venue] / normalisation,
		volumePages = weights[:volumePages] / normalisation,
	)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	totalSimilarityScore(candidate, existing, config)
	totalSimilarityScore(candidate, existing; kwargs...)

Return only the weighted total similarity score used by duplicate detection.
"""
function totalSimilarityScore(candidate::ZettelEntry, existing::ZettelEntry, config::SimilarityConfig)
	return similarityScores(candidate, existing, config).totalScore
end

function totalSimilarityScore(candidate::ZettelEntry, existing::ZettelEntry; kwargs...)
	return similarityScores(candidate, existing, SimilarityConfig(; kwargs...)).totalScore
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	similarityReport(candidate, existing, config)
	similarityReport(candidate, existing; kwargs...)

Return a named tuple describing why two entries are considered too similar, or `nothing` when they do not meet the criteria in `config`.
When `config.contingent == true` the decision is made in a strict ordered chain:
	`author → title → year → booktitle → journal → volume → pages → others`.
At each step, if the score is below its threshold, `nothing` is returned immediately.
There is also a kwargument form that builds a [`SimilarityConfig`](@ref) from `kwargs` and delegates to the primary method.
"""
function similarityReport(candidate::ZettelEntry, existing::ZettelEntry, config::SimilarityConfig)
	scores = similarityScores(candidate, existing, config)

	matchedFieldNames = String[]
	if scores.titleScore ≥ config.titleThreshold
		push!(matchedFieldNames, "title")
	end
	if scores.journalScore ≥ config.venueThreshold
		push!(matchedFieldNames, "journal")
	end
	if scores.booktitleScore ≥ config.venueThreshold
		push!(matchedFieldNames, "booktitle")
	end

	hasComparableBooktitle = haskey(scores.fieldScores, "booktitle")
	hasComparableJournal = haskey(scores.fieldScores, "journal")
	hasComparableVolume = ! isempty(strip(get(candidate.fields, "volume", ""))) && ! isempty(strip(get(existing.fields, "volume", "")))
	hasComparablePages = ! isempty(strip(get(candidate.fields, "pages",  ""))) && ! isempty(strip(get(existing.fields, "pages",  "")))

	if config.contingent
		if scores.authorScore < config.authorThreshold
			return nothing
		end
		if scores.titleScore < config.titleThreshold
			return nothing
		end
		if scores.yearScore < 1.
			return nothing
		end
		if hasComparableBooktitle && scores.booktitleScore < config.venueThreshold
			return nothing
		end
		if hasComparableJournal && scores.journalScore < config.venueThreshold
			return nothing
		end
		if hasComparableVolume && scores.volumeScore < config.volumePagesThreshold
			return nothing
		end
		if hasComparablePages && scores.pagesScore < config.volumePagesThreshold
			return nothing
		end

		for (field, score) ∈ pairs(scores.fieldScores)
			name = lowercase(field)
			if name ∈ ("title", "booktitle", "journal", "volume", "pages")
				continue
			end
			if score < config.otherThreshold
				return nothing
			end
		end
	else
		if scores.yearScore < 1.
			return nothing
		end
		if scores.authorScore < config.authorThreshold
			return nothing
		end
		if scores.keyScore < config.keyThreshold
			return nothing
		end
		if scores.titleScore < config.titleThreshold
			return nothing
		end
		if scores.venueScore < config.venueThreshold
			return nothing
		end
		if scores.volumePagesScore < config.volumePagesThreshold
			return nothing
		end
	end

	if scores.totalScore < config.totalThreshold
		return nothing
	end

	return (
		similar = true,
		existingKey = existing.key,
		matchedFieldNames = matchedFieldNames,
		comparedFields = length(scores.fieldScores),
		textRatio = length(scores.fieldScores) == 0 ? 0. : length(matchedFieldNames) / length(scores.fieldScores),
		textScore = (scores.titleScore + scores.venueScore) / 2,
		fieldScores = scores.fieldScores,
		authorScore = scores.authorScore,
		keyScore = scores.keyScore,
		titleScore = scores.titleScore,
		venueScore = scores.venueScore,
		yearScore = scores.yearScore,
		pagesScore = scores.pagesScore,
		volumeScore = scores.volumeScore,
		volumePagesScore = scores.volumePagesScore,
		totalScore = scores.totalScore,
		totalThreshold = config.totalThreshold,
		candidateAuthor = scores.candidateAuthor,
		existingAuthor = scores.existingAuthor,
		year = scores.year,
		volume = scores.volume,
	)
end

function similarityReport(candidate::ZettelEntry, existing::ZettelEntry; kwargs...)
	config = SimilarityConfig(; kwargs...)
	return similarityReport(candidate, existing, config)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	verySimilarEntry(entry1, entry2, config)

Return `true` when two entries look like duplicates according to `config`.
There is also a keyword-argument form that builds a [`SimilarityConfig`](@ref) from `kwargs`.
"""
function verySimilarEntry(entry1::ZettelEntry, entry2::ZettelEntry, config::SimilarityConfig)
	return ! isnothing(similarityReport(entry1, entry2, config))
end

function verySimilarEntry(entry1::ZettelEntry, entry2::ZettelEntry; kwargs...)
	return ! isnothing(similarityReport(entry1, entry2; kwargs...))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	findVerySimilarEntry(lib, candidate, config)
	findVerySimilarEntry(lib, candidate; kwargs...)

Return the first existing entry in `lib` that looks like a duplicate of `candidate` according to `config`, or `nothing` if no entry matches.
There is also a keyword-argument form that builds a [`SimilarityConfig`](@ref) from `kwargs`.

A positive decision always requires an exact, non-empty year match (`yearScore == 1.0`).
The library is therefore pre-filtered on the candidate year before the expensive per-field similarity work is performed.
"""
function findVerySimilarEntry(lib, candidate::ZettelEntry, config::SimilarityConfig)
	candidateYear = strip(get(candidate.fields, "year", ""))
	if isempty(candidateYear)
		return nothing
	end

	for existing ∈ values(lib)
		if strip(get(existing.fields, "year", "")) ≠ candidateYear
			continue
		end
		report = similarityReport(candidate, existing, config)
		if ! isnothing(report)
			return report
		end
	end

	return nothing
end


function findVerySimilarEntry(lib, candidate::ZettelEntry; kwargs...)
	return findVerySimilarEntry(lib, candidate, SimilarityConfig(; kwargs...))
end


# ----------------------------------------------------------------------------------------------- #
