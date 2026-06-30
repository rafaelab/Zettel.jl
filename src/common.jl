# ----------------------------------------------------------------------------------------------- #
#
const Maybe = Union{Nothing, T} where T


# ----------------------------------------------------------------------------------------------- #
#
# Some journal abbreviations from:
#   - ADS: https://adsabs.harvard.edu/abs_doc/journals1.html
const journalAbbreviationsDict = Dict(
		"\\aap" => "Astronomy and Astrophysics",
		"\\aapr" => "Astronomy and Astrophysics Reviews",
		"\\aaps" => "Astronomy and Astrophysics Reviews, Supplement",
		"\\actaa" => "Acta Astronomica",
		"\\aj" => "The Astronomical Journal",
		"\\ao" => "Applied Optics",
		"\\apj" => "The Astrophysical Journal",
		"\\apjl" => "The Astrophysical Journal Letters",
		"\\apjs" => "The Astrophysical Journal, Supplement",
		"\\aplett" => "Astrophysics Letters",
		"\\apss" => "Astrophysics and Space Science",
		"\\araa" => "Annual Review of Astronomy and Astrophysics",
		"\\baas" => "Bulletin of the AAS",
		"\\bain" => "Bulletin Astronomical Institute of the Netherlands",
		"\\caa" => "Chinese Astronomy and Astrophysics",
		"\\cjaa" => "Chinese Journal of Astronomy and Astrophysics",
		"\\grl" => "Geophysics Research Letters",
		"\\icarus" => "Icarus",
		"\\jcap" => "Journal of Cosmology and Astroparticle Physics",
		"\\jcp" => "Journal of Chemical Physics",
		"\\jgr" => "Journal of Geophysics Research",
		"\\jqsrt" => "Journal of Quantitative Spectroscopy and Radiative Transfer",
		"\\jrasc" => "Journal of the Royal Astronomical Society of Canada",
		"\\memras" => "Memoirs of the Royal Astronomical Society",
		"\\memsai" => "Memorie della Società Astronomica Italiana",
		"\\mnras" => "Monthly Notices of the Royal Astronomical Society",
		"\\na" => "New Astronomy",
		"\\nar" => "New Astronomy Review",
		"\\nat" => "Nature",
		"\\nphysa" => "Nuclear Physics A",
		"\\psj" => "Planetary Science Journal",
		"\\pasa" => "Publications of the Astronomical Society of Australia",
		"\\pasj" => "Publications of the Astronomical Society of Japan",
		"\\pasp" => "Publications of the Astronomical Society of the Pacific",
		"\\physrep" => "Physics Reports",
		"\\physscr" => "Physics Scripta",
		"\\planss" => "Planetary Space Science",
		"\\pra" => "Physical Review A",
		"\\prb" => "Physical Review B",
		"\\prc" => "Physical Review C",
		"\\prd" => "Physical Review D",
		"\\pre" => "Physical Review E",
		"\\prl" => "Physical Review Letters",
		"\\prx" => "Physical Review X",
		"\\qjras" => "Quarterly Journal of the Royal Astronomical Society",
		"\\sovast" => "Soviet Astronomy",
		"\\ssr" => "Space Science Reviews",
		"\\zap" => "Zeitschrift fuer Astrophysik",
	)

# ----------------------------------------------------------------------------------------------- #
#
const monthsDict = Dict(
	"jan" => "01",
	"feb" => "02",
	"mar" => "03",
	"apr" => "04",
	"may" => "05",
	"jun" => "06",
	"jul" => "07",
	"aug" => "08",
	"sep" => "09",
	"oct" => "10",
	"nov" => "11",
	"dec" => "12",
	"january" => "01",
	"february" => "02",
	"march" => "03",
	"april" => "04",
	"may" => "05",
	"june" => "06",
	"july" => "07",
	"august" => "08",
	"september" => "09",
	"october" => "10",
	"november" => "11",
	"december" => "12",
)


# ----------------------------------------------------------------------------------------------- #
#                                      ProgressBar configurations                                 #
# ----------------------------------------------------------------------------------------------- #

# Progress reporting using ProgressMeter.jl.
# Long operations show a single progress bar that updates in place instead of emitting the same log message many times. 
# The active `Progress` object is held module-globally so the existing `reportTotal` / `reportProgress` call sites keep their simple, stateless signatures.

const progressThresholdEntries = 25
const _progress = Ref{Union{Nothing, Progress}}(nothing)


function _startProgress(description::AbstractString, totalCount::Integer)
	bar = Progress(Int(totalCount); desc = string(strip(description), ": "), showspeed = true)
	_progress[] = bar
	return bar
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	reportTotal(statusMessage, totalCount)

Begin a [`ProgressMeter`](https://github.com/timholy/ProgressMeter.jl) progress bar for an operation processing `totalCount` items. 
No-op for small operations (`totalCount < progressThresholdEntries`).
"""
function reportTotal(statusMessage::AbstractString, totalCount::Integer)
	if totalCount < progressThresholdEntries
		_progress[] = nothing
		return nothing
	end

	_startProgress(statusMessage, totalCount)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	reportProgress(statusMessage, currentCount, totalCount)

Advance the active progress bar to `currentCount` of `totalCount`. 
If no bar is active (no preceding `reportTotal`), one is started lazily using `statusMessage`. 
ProgressMeter throttles the redraws; the bar is finished once `currentCount` reaches `totalCount`.
"""
function reportProgress(statusMessage::AbstractString, currentCount::Integer, totalCount::Integer)
	if totalCount < progressThresholdEntries
		return nothing
	end

	bar = _progress[]
	if isnothing(bar)
		bar = _startProgress(statusMessage, totalCount)
	end

	update!(bar, Int(currentCount))
	if currentCount ≥ totalCount
		finish!(bar)
		_progress[] = nothing
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
