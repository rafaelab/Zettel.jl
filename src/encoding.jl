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

# Input
- `s` [`AbstractString`]: string possibly containing TeX character commands.

# Output
- A new `String` with TeX sequences replaced by UTF-8 characters.
"""
function decodeTex(s::AbstractString)
	result = String(s)

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
