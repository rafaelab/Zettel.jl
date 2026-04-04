# ----------------------------------------------------------------------------------------------- #
#
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


# ----------------------------------------------------------------------------------------------- #
#
# Reverse mapping: UTF-8 characters to TeX sequences.
# ASCII double quote (") is excluded as it has no unique TeX equivalent — "``" and "''" both
# produce it when decoding, so round-tripping is context-dependent.
const utf8ToTex = begin
	d = Dict{String, String}()
	for (tex, utf) ∈ tex2utf8
		d[utf] = tex
	end
	d
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	decodeTex(s)

Convert TeX character commands in `s` to their UTF-8 equivalents using the [`tex2utf8`](@ref) table.

Replacements are applied longest-key-first to avoid partial matches (e.g. `\\v{c}` is tried before a hypothetical `\\v`).

# Input
- `s::AbstractString`: string possibly containing TeX character commands.

# Output
- A new `String` with TeX sequences replaced by UTF-8 characters.
"""
function decodeTex(s::AbstractString)
	result = String(s)
	for tex ∈ sort(collect(keys(tex2utf8)); by = length, rev = true)
		result = replace(result, tex => tex2utf8[tex])
	end
	return result
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	encodeTex(s)

Convert UTF-8 characters in `s` to their TeX equivalents using the [`utf8ToTex`](@ref) table.

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
	for utf ∈ sort(collect(keys(utf8ToTex)); by = length, rev = true)
		result = replace(result, utf => utf8ToTex[utf])
	end
	return result
end


# ----------------------------------------------------------------------------------------------- #
