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
	return d
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	decodeTex(s)

Convert TeX character commands in `s` to their UTF-8 equivalents using the `tex2utf8` table.
Replacements are applied longest-key-first to avoid partial matches (e.g. `\\v{c}` is tried before a hypothetical `\\v`).

# Input
- `s::AbstractString`: string possibly containing TeX character commands.

# Output
- A new `String` with TeX sequences replaced by UTF-8 characters.
"""
function decodeTex(s::AbstractString)
	result = String(s)
	
	# normalise grouped accent macros (e.g. {\"o} -> \"o) first
	result = replace(result, r"\{\\([\"'`^~=])([A-Za-z])\}" => s"\\\1\2")
	result = replace(result, r"\{\\([\"'`^~=])\{([A-Za-z])\}\}" => s"\\\1\2")
	
	# normalise accent macros written with a braced single letter (e.g. {\"o} -> \"o) so they are handled by the lookup table
	result = replace(result, r"\\([\"'`^~=])\{([A-Za-z])\}" => s"\\\1\2")
	for tex ∈ sort(collect(keys(tex2utf8)); by = length, rev = true)
		result = replace(result, tex => tex2utf8[tex])
	end

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

Replacements are applied longest-key-first.
Note: left/right curly quotes (`\u201C`/`\u201D`) are encoded as ` `` ` and `''` respectively.
ASCII double quote (`"`) has no unique TeX equivalent and is left unchanged.

# Input
- `s::AbstractString`: string possibly containing UTF-8 characters.

# Output
- A new `String` with UTF-8 characters replaced by TeX sequences.
"""
function encodeTex(s::AbstractString)
	result = String(s)
	mapping = isdefined(@__MODULE__, :utf8ToTex) ? getfield(@__MODULE__, :utf8ToTex) : Dict{String, String}(utf => tex for (tex, utf) ∈ tex2utf8)
	for utf ∈ sort(collect(keys(mapping)); by = length, rev = true)
		result = replace(result, utf => mapping[utf])
	end
	return result
end


# ----------------------------------------------------------------------------------------------- #
