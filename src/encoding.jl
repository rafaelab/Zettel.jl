export
	decodeTex,
	encodeTex


# ----------------------------------------------------------------------------------------------- #
#
# TeX character encoding/decoding TeX sequences to UTF-8.
const tex2utf8 = Dict(
	# No-argument letter macros and ligatures. The trailing `{}` is only a
	# terminator; `_noArgLetterMacros` (below) lets them decode as `\l`, `\l{}`,
	# `\l ` or `{\l}` interchangeably.
	#
	# Accented letters are deliberately NOT listed here. Every accent (acute,
	# grave, circumflex, diaeresis, tilde, macron, caron, breve, double acute,
	# ogonek, dot above, cedilla, ...) is decoded generically from
	# `texAccentCombining` by `_decodeAccentMacro` and re-encoded by
	# `_encodeAccentFallback`. Listing them explicitly only duplicated that
	# engine, so the table is kept to the cases the engine cannot derive.
	"\\ss{}" => "ß",
	"\\i{}" => "ı",
	"\\j{}" => "ȷ",
	"\\ae{}" => "æ",
	"\\AE{}" => "Æ",
	"\\o{}" => "ø",
	"\\O{}" => "Ø",
	"\\aa{}" => "å",
	"\\AA{}" => "Å",
	"\\l{}" => "ł",
	"\\L{}" => "Ł",

	# ASCII tilde macro (common in some BibTeX exports)
	"\\textasciitilde" => "~",
	"\\textasciitilde{}" => "~",

	# common punctuation / symbols
	"---" => "—",
	"--" => "–",
	"``" => "\u201C",
	"''" => "\u201D",

)


# Reverse mapping: UTF-8 characters to TeX sequences.
# ASCII double quote (") is excluded as it has no unique TeX equivalent.
# This is because "``" and "''" both produce it when decoding, so round-tripping is context-dependent.
const utf8ToTex = begin
	d = Dict{String, String}()
	for (tex, utf) ∈ tex2utf8
		d[utf] = tex
	end
	d
end

const _tex2utf8SortedKeys = sort(collect(keys(tex2utf8)); by = length, rev = true)


# No-argument letter macros (e.g. `\ss`, `\l`, `\ae`) harvested from the lookup table.
# These commands take no argument, so the trailing `{}` in the table keys is only a terminator: in real BibTeX they appear as `\l`, `\l{}`, `\l ` or `{\l}` interchangeably.
# Decoding them independently of that terminator keeps the mapping from breaking down when braces or whitespace are present.
const _noArgLetterMacros = let
	d = Dict{String, String}()
	for (tex, utf) ∈ tex2utf8
		m = match(r"^\\([A-Za-z]+)\{\}$", tex)
		isnothing(m) || (d[String(m.captures[1])] = utf)
	end
	d
end

const _noArgLetterMacroNames = sort(collect(keys(_noArgLetterMacros)); by = length, rev = true)


# Generic TeX accent fallback for cases not explicitly listed in `tex2utf8`.
const texAccentCombining = Dict(
	"'" => '\u0301',   # acute
	"`" => '\u0300',   # grave
	"^" => '\u0302',   # circumflex
	"\"" => '\u0308',  # diaeresis
	"~" => '\u0303',   # tilde
	"=" => '\u0304',   # macron
	"u" => '\u0306',   # breve
	"." => '\u0307',   # dot above
	"H" => '\u030B',   # double acute
	"v" => '\u030C',   # caron
	"c" => '\u0327',   # cedilla
	"k" => '\u0328',   # ogonek
	"r" => '\u030A',   # ring above
	"d" => '\u0323',   # dot below
	"b" => '\u0331',   # macron below
)

const combiningToTexAccent = Dict(v => k for (k, v) ∈ texAccentCombining)


# `\ensuremath` is unwrapped into plain `$...$` math (see `_decodeEnsuremath`).
const _ensuremathMacro = "\\ensuremath"


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_startsEnsuremath(text, i)

Return `true` when `\\ensuremath` starts at index `i` of `text` and is not merely the prefix of a longer macro name (e.g. `\\ensuremathematics` does not match).
"""
function _startsEnsuremath(text::AbstractString, i::Integer)
	if ! startswith(SubString(text, i), _ensuremathMacro)
		return false
	end

	after = nextind(text, i, length(_ensuremathMacro))
	if after > lastindex(text)
		return true
	end

	c = text[after]
	return ! (isascii(c) && isletter(c))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_matchingBrace(text, openIdx)

Index of the `}` that closes the `{` at `openIdx`, or `nothing` when the group is never closed.
Nesting is respected, so `{\\frac{a}{b}}` returns the final brace, and escaped braces (`\\{`, `\\}`) are not counted as delimiters.
"""
function _matchingBrace(text::AbstractString, openIdx::Integer)
	depth = 0
	i = openIdx
	while i ≤ lastindex(text)
		c = text[i]
		if c == '\\'
			# skip the escaped character, so `\{` and `\}` do not change the depth
			i = nextind(text, i)
			i ≤ lastindex(text) && (i = nextind(text, i))
			continue
		elseif c == '{'
			depth += 1
		elseif c == '}'
			depth -= 1
			if depth == 0
				return i
			end
		end
		i = nextind(text, i)
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_decodeEnsuremath(s, inMath = false)

Rewrite `\\ensuremath` into ordinary TeX math, so `\\ensuremath{\\beta}` becomes `\$\\beta\$`.

The argument is taken as a brace-balanced group (`\\ensuremath{\\frac{a}{b}}` gives `\$\\frac{a}{b}\$`) or, when no braces are given, as a single macro token (`\\ensuremath\\beta` gives `\$\\beta\$`).
An empty argument is dropped rather than turned into an empty `\$\$`, and an unterminated group is left untouched.

`inMath` tracks whether the scan currently sits inside a `\$...\$` region; there the wrapper is only removed, as nesting `\$` inside `\$` would produce invalid TeX.
It is also how nested `\\ensuremath` is handled: the argument is decoded with `inMath = true`, so only the outermost occurrence introduces delimiters.

# Input
- `s` [`AbstractString`]: string possibly containing `\\ensuremath`.
- `inMath` [`Bool`]: whether `s` is already the contents of a math region.

# Output
- A new `String` with every `\\ensuremath` wrapper removed.
"""
function _decodeEnsuremath(s::AbstractString, inMath::Bool = false)
	text = String(s)
	if ! occursin(_ensuremathMacro, text)
		return text
	end

	io = IOBuffer()
	i = firstindex(text)
	while i ≤ lastindex(text)
		c = text[i]

		if c == '\\' && ! _startsEnsuremath(text, i)
			# copy the escape and whatever it escapes, so `\$` is never read as a math delimiter
			print(io, c)
			i = nextind(text, i)
			if i ≤ lastindex(text)
				print(io, text[i])
				i = nextind(text, i)
			end
			continue
		end

		if c == '$'
			# `$$` opens or closes display math as a unit, so it must toggle once and not twice
			j = nextind(text, i)
			if j ≤ lastindex(text) && text[j] == '$'
				print(io, "\$\$")
				i = nextind(text, j)
			else
				print(io, '$')
				i = j
			end
			inMath = ! inMath
			continue
		end

		if ! _startsEnsuremath(text, i)
			print(io, c)
			i = nextind(text, i)
			continue
		end

		# `\ensuremath` starts here: locate its argument, tolerating whitespace before it
		afterMacro = nextind(text, i, length(_ensuremathMacro))
		k = afterMacro
		while k ≤ lastindex(text) && isspace(text[k])
			k = nextind(text, k)
		end

		argument = nothing
		nextIdx = afterMacro
		if k ≤ lastindex(text) && text[k] == '{'
			closeIdx = _matchingBrace(text, k)
			if ! isnothing(closeIdx)
				inner = SubString(text, nextind(text, k), prevind(text, closeIdx))
				argument = strip(_decodeEnsuremath(inner, true))
				nextIdx = nextind(text, closeIdx)
			end
		elseif k ≤ lastindex(text) && text[k] == '\\'
			# unbraced form: the argument is the single macro token that follows
			m = nextind(text, k)
			while m ≤ lastindex(text) && isascii(text[m]) && isletter(text[m])
				m = nextind(text, m)
			end
			if m > nextind(text, k)
				argument = SubString(text, k, prevind(text, m))
				nextIdx = m
			end
		end

		if isnothing(argument)
			# no argument we can claim (or an unclosed group): leave the macro as it was written
			print(io, _ensuremathMacro)
		elseif ! isempty(argument)
			print(io, inMath ? argument : "\$" * argument * "\$")
		end
		i = nextIdx
	end

	return String(take!(io))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_decodeAccentMacro(accent, letter)

Helper function for `decodeTex` that attempts to decode a TeX accent macro (e.g. `\v{t}`). 
It works by decomposing the resulting character and checking if it consists of the expected letter and a combining accent with a known TeX equivalent.
"""
function _decodeAccentMacro(accent::AbstractString, letter::AbstractString)
	if ! haskey(texAccentCombining, accent)
		return nothing
	end
	if length(letter)  ≠ 1
		return nothing
	end
	combined = Base.Unicode.normalize(letter * string(texAccentCombining[accent]), :NFC)
	return length(combined) == 1 ? combined : nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_encodeAccentFallback(ch)

Fallback encoding for UTF-8 characters that are not explicitly listed in `utf8ToTex`.
If `ch` can be decomposed into a single ASCII letter and a single combining accent that has a TeX equivalent in `texAccentCombining`. 
Return the corresponding TeX macro (e.g. `\v{t}` for ť). 
Otherwise, return `ch` unchanged.
"""
function _encodeAccentFallback(ch::Char)
	decomposed = Base.Unicode.normalize(string(ch), :NFD)
	parts = collect(decomposed)
	if length(parts) ≠ 2 
		return string(ch)
	end
	if ! isascii(parts[1])
		return string(ch)
	end
	if ! haskey(combiningToTexAccent, parts[2])
		return string(ch)
	end

	accent = combiningToTexAccent[parts[2]]
	letter = string(parts[1])
	if accent ∈ ("'", "`", "^", "\"", "~", "=")
		return "\\$(accent)$(letter)"
	end

	return "\\$(accent){$(letter)}"
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	decodeTex(s)

Convert TeX character commands in `s` to their UTF-8 equivalents using the `tex2utf8` table.
Replacements are applied longest-key-first to avoid partial matches (e.g. `\\v{c}` is tried before a hypothetical `\\v`).

The decoder is tolerant of grouping braces and whitespace: `{{\\'a}}`, `{ \\'a }` and `\\'a` all decode to `á`, and no-argument macros decode regardless of a trailing `{}` (e.g. `\\l`, `\\l{}` and `{\\l}` all give `ł`). The BibTeX escape `\\&` is decoded to a plain `&`.

`\\ensuremath` wrappers are rewritten as ordinary math, so a title carrying `\\ensuremath{\\beta}` is stored as `\$\\beta\$` (see `_decodeEnsuremath`).

# Input
- `s` [`AbstractString`]: string possibly containing TeX character commands.

# Output
- A new `String` with TeX sequences replaced by UTF-8 characters.
"""
function decodeTex(s::AbstractString)
	result = String(s)

	# `\ensuremath{...}` -> `$...$`, done first because the brace normalisation below would
	# otherwise rewrite the braces that delimit its argument.
	result = _decodeEnsuremath(result)

	# literal escaped specials used by BibTeX: `\&` -> `&` so JSON/YAML keep plain UTF-8.
	result = replace(result, "\\&" => "&")

	# normalise grouped accent macros first, tolerating nested braces and surrounding
	# whitespace: {\"o}, { \"o }, {\"{o}} and {{\"o}} all collapse to \"o.
	result = replace(result, r"\{\s*\\([\"'`^~=])\s*\{\s*([A-Za-z])\s*\}\s*\}" => s"\\\1\2")
	result = replace(result, r"\{\s*\\([\"'`^~=])\s*([A-Za-z])\s*\}" => s"\\\1\2")
	result = replace(result, r"\{\s*\\([ij])\s*\}" => s"\\\1")

	# normalise accent macros written with a braced single letter (e.g. \"{o} -> \"o)
	result = replace(result, r"\\([\"'`^~=])\s*\{\s*([A-Za-z])\s*\}" => s"\\\1\2")

	# no-argument letter macros (\ss, \l, \ae, ...), robust to braces, a trailing `{}` or
	# whitespace: \l, \l{}, \l  and {\l} all decode to the same glyph.
	for name ∈ _noArgLetterMacroNames
		rx = Regex("\\\\" * name * "(?![A-Za-z])(?:\\{\\})?")
		result = replace(result, rx => _noArgLetterMacros[name])
	end

	for tex ∈ _tex2utf8SortedKeys
		result = replace(result, tex => tex2utf8[tex])
	end

	# generic decoder for braced accent macros (e.g. \v{c} -> č, \'{a} -> á)
	# e.g. \v{t} -> ť  (whitespace inside the braces is tolerated)
	result = replace(result, r"\\([A-Za-z\"'`^~=\.])\s*\{\s*([A-Za-z])\s*\}" => (matched -> begin
		m = match(r"^\\([A-Za-z\"'`^~=\.])\s*\{\s*([A-Za-z])\s*\}$", String(matched))
		if isnothing(m)
			return String(matched)
		end
		decoded = _decodeAccentMacro(m.captures[1], m.captures[2])
		return isnothing(decoded) ? String(matched) : decoded
	end))

	# generic fallback for classic unbraced accent macros
	result = replace(result,
		r"\\([\"'`^~=\.])([A-Za-z])" => (
			matched -> begin
				m = match(r"^\\([\"'`^~=\.])([A-Za-z])$", String(matched))
				if isnothing(m)
					return String(matched)
				end
				decoded = _decodeAccentMacro(m.captures[1], m.captures[2])
				return isnothing(decoded) ? String(matched) : decoded
			end
		)
	)

	# some BibTeX parsers preserve grouping braces around already-decoded glyphs (e.g. M{ü}ller)
	# drop those wrappers (tolerating whitespace) while keeping ASCII-protection braces
	result = replace(result, r"\{\s*([^\x00-\x7F])\s*\}" => s"\1")

	return result
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	encodeTex(s)

Convert UTF-8 characters in `s` to their TeX equivalents using the `utf8ToTex` table.

Note: left/right curly quotes (`\u201C`/`\u201D`) are encoded as ` `` ` and `''` respectively.
ASCII double quote (`"`) has no unique TeX equivalent and is left unchanged.
A plain `&` is escaped to `\\&` so BibTeX output stays valid (e.g. "A&A" -> "A\\&A").

# Input
- `s` [`AbstractString`]: string possibly containing UTF-8 characters.

# Output
- A new `String` with UTF-8 characters replaced by TeX sequences.
"""
function encodeTex(s::AbstractString)
	mapping = utf8ToTex

	# Encode one source character at a time to avoid remapping inside generated TeX snippets.
	# Example: ñ -> \~n should not then rewrite ~ as \textasciitilde{}.
	io = IOBuffer()
	for ch ∈ String(s)
		chs = string(ch)
		if haskey(mapping, chs)
			print(io, mapping[chs])
		elseif ch == '&'
			# `&` is always special in (La)TeX and must be escaped in BibTeX values
			# (e.g. the journal "A&A" -> "A\&A"); JSON/YAML keep the plain `&`.
			print(io, "\\&")
		elseif isascii(ch)
			print(io, ch)
		else
			print(io, _encodeAccentFallback(ch))
		end
	end

	return String(take!(io))
end


# ----------------------------------------------------------------------------------------------- #
