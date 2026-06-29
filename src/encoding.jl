export
	decodeTex,
	encodeTex


# ----------------------------------------------------------------------------------------------- #
#
# TeX character encoding/decoding TeX sequences to UTF-8.
const tex2utf8 = Dict(
	"\\ss{}" => "ß",
	"\\i{}" => "ı",
	"\\j{}" => "ȷ",

	# tildes
	"\\~a" => "ã",
	"\\~A" => "Ã",
	"\\~n" => "ñ",
	"\\~N" => "Ñ",
	"\\~o" => "õ",
	"\\~O" => "Õ",

	# ASCII tilde macro (common in some BibTeX exports)
	"\\textasciitilde" => "~",
	"\\textasciitilde{}" => "~",

	# cedilla
	"\\c{c}" => "ç",
	"\\c{C}" => "Ç",

	# ligatures
	"\\ae{}" => "æ",
	"\\AE{}" => "Æ",
	"\\o{}" => "ø",
	"\\O{}" => "Ø",
	"\\aa{}" => "å",
	"\\AA{}" => "Å",

	# polish / baltic
	"\\l{}" => "ł",
	"\\L{}" => "Ł",

	# acute
	"\\'a" => "á",
	"\\'A" => "Á",
	"\\'e" => "é",
	"\\'E" => "É",
	"\\'i" => "í",
	"\\'I" => "Í",
	"\\'o" => "ó",
	"\\'O" => "Ó",
	"\\'u" => "ú",
	"\\'U" => "Ú",
	"\\'y" => "ý",
	"\\'Y" => "Ý",

	# diaeresis / umlaut
	"\\\"a" => "ä",
	"\\\"A" => "Ä",
	"\\\"e" => "ë",
	"\\\"E" => "Ë",
	"\\\"i" => "ï",
	"\\\"I" => "Ï",
	"\\\"o" => "ö",
	"\\\"O" => "Ö",
	"\\\"u" => "ü",
	"\\\"U" => "Ü",
	"\\\"y" => "ÿ",

	# circumflex
	"\\^a" => "â",
	"\\^A" => "Â",
	"\\^e" => "ê",
	"\\^E" => "Ê",
	"\\^i" => "î",
	"\\^I" => "Î",
	"\\^o" => "ô",
	"\\^O" => "Ô",
	"\\^u" => "û",
	"\\^U" => "Û",

	# grave
	"\\`a" => "à",
	"\\`A" => "À",
	"\\`e" => "è",
	"\\`E" => "È",
	"\\`i" => "ì",
	"\\`I" => "Ì",
	"\\`o" => "ò",
	"\\`O" => "Ò",
	"\\`u" => "ù",
	"\\`U" => "Ù",

	# caron (háček)
	"\\v{c}" => "č",
	"\\v{C}" => "Č",
	"\\v{s}" => "š",
	"\\v{S}" => "Š",
	"\\v{z}" => "ž",
	"\\v{Z}" => "Ž",
	"\\v{r}" => "ř",
	"\\v{R}" => "Ř",
	"\\v{l}" => "ľ",
	"\\v{L}" => "Ľ",

	# macron
	"\\=a" => "ā",
	"\\=A" => "Ā",
	"\\=e" => "ē",
	"\\=E" => "Ē",
	"\\=i" => "ī",
	"\\=I" => "Ī",
	"\\=o" => "ō",
	"\\=O" => "Ō",
	"\\=u" => "ū",
	"\\=U" => "Ū",

	# breve
	"\\u{a}" => "ă",
	"\\u{A}" => "Ă",
	"\\u{g}" => "ğ",
	"\\u{G}" => "Ğ",

	# double acute
	"\\H{o}" => "ő",
	"\\H{O}" => "Ő",
	"\\H{u}" => "ű",
	"\\H{U}" => "Ű",

	# ogonek
	"\\k{a}" => "ą",
	"\\k{A}" => "Ą",
	"\\k{e}" => "ę",
	"\\k{E}" => "Ę",

	# dot above
	"\\.{z}" => "ż",
	"\\.{Z}" => "Ż",
	"\\.{e}" => "ė",
	"\\.{E}" => "Ė",

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

Helper function for `decodeTex` that attempts to decode a TeX accent macro (e.g. `\v{t}`) by decomposing the resulting character and checking if it consists of the expected letter and a combining accent with a known TeX equivalent.
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

# Input
- `s` [`AbstractString`]: string possibly containing TeX character commands.

# Output
- A new `String` with TeX sequences replaced by UTF-8 characters.
"""
function decodeTex(s::AbstractString)
	result = String(s)
	
	# normalise grouped accent macros (e.g. {\"o} -> \"o) first
	result = replace(result, r"\{\\([\"'`^~=])([A-Za-z])\}" => s"\\\1\2")
	result = replace(result, r"\{\\([\"'`^~=])\{([A-Za-z])\}\}" => s"\\\1\2")
	result = replace(result, r"\{\\([ij])\}" => s"\\\1")
	
	# normalise accent macros written with a braced single letter (e.g. {\"o} -> \"o) so they are handled by the lookup table
	result = replace(result, r"\\([\"'`^~=])\{([A-Za-z])\}" => s"\\\1\2")
	for tex ∈ _tex2utf8SortedKeys
		result = replace(result, tex => tex2utf8[tex])
	end

	# dotless i/j when written as \i or \j (without trailing {})
	result = replace(result, r"\\i(?![A-Za-z])" => "ı")
	result = replace(result, r"\\j(?![A-Za-z])" => "ȷ")

	# generic fallback for braced accent macros not explicitly present in `tex2utf8`
	# e.g. \v{t} -> ť
	result = replace(result, r"\\([A-Za-z\"'`^~=\.])\{([A-Za-z])\}" => (matched -> begin
		m = match(r"^\\([A-Za-z\"'`^~=\.])\{([A-Za-z])\}$", String(matched))
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
	# drop those wrappers while keeping ASCII-protection braces
	result = replace(result, r"\{([^\x00-\x7F])\}" => s"\1")
	
	return result
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	encodeTex(s)

Convert UTF-8 characters in `s` to their TeX equivalents using the `utf8ToTex` table.

Note: left/right curly quotes (`\u201C`/`\u201D`) are encoded as ` `` ` and `''` respectively.
ASCII double quote (`"`) has no unique TeX equivalent and is left unchanged.

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
		elseif isascii(ch)
			print(io, ch)
		else
			print(io, _encodeAccentFallback(ch))
		end
	end

	return String(take!(io))
end


# ----------------------------------------------------------------------------------------------- #
