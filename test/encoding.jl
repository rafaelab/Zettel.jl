# ----------------------------------------------------------------------------------------------- #
#
@testset "decodeTex" begin

	@testset "acute accents" begin
		@test decodeTex("\\'a") == "á"
		@test decodeTex("\\'A") == "Á"
		@test decodeTex("\\'e") == "é"
		@test decodeTex("\\'E") == "É"
		@test decodeTex("\\'i") == "í"
		@test decodeTex("\\'I") == "Í"
		@test decodeTex("\\'o") == "ó"
		@test decodeTex("\\'O") == "Ó"
		@test decodeTex("\\'u") == "ú"
		@test decodeTex("\\'U") == "Ú"
		@test decodeTex("\\'y") == "ý"
		@test decodeTex("\\'Y") == "Ý"
	end

	@testset "grave accents" begin
		@test decodeTex("\\`a") == "à"
		@test decodeTex("\\`A") == "À"
		@test decodeTex("\\`e") == "è"
		@test decodeTex("\\`E") == "È"
		@test decodeTex("\\`i") == "ì"
		@test decodeTex("\\`I") == "Ì"
		@test decodeTex("\\`o") == "ò"
		@test decodeTex("\\`O") == "Ò"
		@test decodeTex("\\`u") == "ù"
		@test decodeTex("\\`U") == "Ù"
	end

	@testset "circumflex accents" begin
		@test decodeTex("\\^a") == "â"
		@test decodeTex("\\^A") == "Â"
		@test decodeTex("\\^e") == "ê"
		@test decodeTex("\\^E") == "Ê"
		@test decodeTex("\\^i") == "î"
		@test decodeTex("\\^I") == "Î"
		@test decodeTex("\\^o") == "ô"
		@test decodeTex("\\^O") == "Ô"
		@test decodeTex("\\^u") == "û"
		@test decodeTex("\\^U") == "Û"
	end

	@testset "diaeresis / umlaut" begin
		@test decodeTex("\\\"a") == "ä"
		@test decodeTex("\\\"A") == "Ä"
		@test decodeTex("\\\"e") == "ë"
		@test decodeTex("\\\"E") == "Ë"
		@test decodeTex("\\\"i") == "ï"
		@test decodeTex("\\\"I") == "Ï"
		@test decodeTex("\\\"o") == "ö"
		@test decodeTex("\\\"O") == "Ö"
		@test decodeTex("\\\"u") == "ü"
		@test decodeTex("\\\"U") == "Ü"
		@test decodeTex("\\\"y") == "ÿ"
	end

	@testset "tilde" begin
		@test decodeTex("\\~a") == "ã"
		@test decodeTex("\\~A") == "Ã"
		@test decodeTex("\\~n") == "ñ"
		@test decodeTex("\\~N") == "Ñ"
		@test decodeTex("\\~o") == "õ"
		@test decodeTex("\\~O") == "Õ"
	end

	@testset "caron (háček)" begin
		@test decodeTex("\\v{c}") == "č"
		@test decodeTex("\\v{C}") == "Č"
		@test decodeTex("\\v{s}") == "š"
		@test decodeTex("\\v{S}") == "Š"
		@test decodeTex("\\v{z}") == "ž"
		@test decodeTex("\\v{Z}") == "Ž"
		@test decodeTex("\\v{r}") == "ř"
		@test decodeTex("\\v{R}") == "Ř"
		@test decodeTex("\\v{l}") == "ľ"
		@test decodeTex("\\v{L}") == "Ľ"
		# fallback for chars not in the explicit table
		@test decodeTex("\\v{t}") == "ť"
		@test decodeTex("\\v{T}") == "Ť"
		@test decodeTex("\\v{n}") == "ň"
		@test decodeTex("\\v{N}") == "Ň"
		@test decodeTex("\\v{d}") == "ď"
		@test decodeTex("\\v{D}") == "Ď"
	end

	@testset "macron" begin
		@test decodeTex("\\=a") == "ā"
		@test decodeTex("\\=A") == "Ā"
		@test decodeTex("\\=e") == "ē"
		@test decodeTex("\\=E") == "Ē"
		@test decodeTex("\\=i") == "ī"
		@test decodeTex("\\=I") == "Ī"
		@test decodeTex("\\=o") == "ō"
		@test decodeTex("\\=O") == "Ō"
		@test decodeTex("\\=u") == "ū"
		@test decodeTex("\\=U") == "Ū"
	end

	@testset "breve" begin
		@test decodeTex("\\u{a}") == "ă"
		@test decodeTex("\\u{A}") == "Ă"
		@test decodeTex("\\u{g}") == "ğ"
		@test decodeTex("\\u{G}") == "Ğ"
	end

	@testset "double acute" begin
		@test decodeTex("\\H{o}") == "ő"
		@test decodeTex("\\H{O}") == "Ő"
		@test decodeTex("\\H{u}") == "ű"
		@test decodeTex("\\H{U}") == "Ű"
	end

	@testset "ogonek" begin
		@test decodeTex("\\k{a}") == "ą"
		@test decodeTex("\\k{A}") == "Ą"
		@test decodeTex("\\k{e}") == "ę"
		@test decodeTex("\\k{E}") == "Ę"
	end

	@testset "dot above" begin
		@test decodeTex("\\.{z}") == "ż"
		@test decodeTex("\\.{Z}") == "Ż"
		@test decodeTex("\\.{e}") == "ė"
		@test decodeTex("\\.{E}") == "Ė"
	end

	@testset "cedilla" begin
		@test decodeTex("\\c{c}") == "ç"
		@test decodeTex("\\c{C}") == "Ç"
	end

	@testset "ligatures and special letters" begin
		@test decodeTex("\\ae{}") == "æ"
		@test decodeTex("\\AE{}") == "Æ"
		@test decodeTex("\\o{}") == "ø"
		@test decodeTex("\\O{}") == "Ø"
		@test decodeTex("\\aa{}") == "å"
		@test decodeTex("\\AA{}") == "Å"
		@test decodeTex("\\l{}") == "ł"
		@test decodeTex("\\L{}") == "Ł"
		@test decodeTex("\\ss{}") == "ß"
		@test decodeTex("\\i{}") == "ı"
		@test decodeTex("\\j{}") == "ȷ"
	end

	@testset "punctuation" begin
		@test decodeTex("---") == "—"
		@test decodeTex("--") == "–"
		@test decodeTex("``") == "“"
		@test decodeTex("''") == "”"
	end

	@testset "embedded in string" begin
		@test decodeTex("Schr\\\"odinger") == "Schrödinger"
		@test decodeTex("Caf\\'e au lait") == "Café au lait"
		@test decodeTex("na\\\"ive") == "naïve"
		@test decodeTex("Zur Elektrodynamik bewegter K{\\\"o}rper") == "Zur Elektrodynamik bewegter Körper"
		@test decodeTex("S\\v{t}astn\\'y") == "Sťastný"
		@test decodeTex("Sakall{\\i}, {\\.I}.") == "Sakallı, İ."
		@test decodeTex("\\v{S}ar\\v{c}evi\\'c") == "Šarčević"
		@test decodeTex("Mu\\~noz-Gonz\\'alez") == "Muñoz-González"
		@test decodeTex("\\k{A}nkiewicz") == "Ąnkiewicz"
		@test decodeTex("Sahl\\'en") == "Sahlén"
		@test decodeTex("P\\'erez-Garc\\'ia") == "Pérez-García"
	end

	@testset "no-op on plain ASCII" begin
		@test decodeTex("hello world") == "hello world"
		@test decodeTex("") == ""
	end

	@testset "grouped braces" begin
		@test decodeTex("{\\'a}") == "á"
		@test decodeTex("{\\'{a}}") == "á"
		@test decodeTex("{\\\"{o}}") == "ö"
		@test decodeTex("M{\\\"{u}}ller") == "Müller"
		@test decodeTex("{\\v{S}}ar{\\v{c}}evi{\\'c}") == "Šarčević"
		@test decodeTex("{\\H{o}}") == "ő"
		@test decodeTex("{\\k{a}}") == "ą"
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "encodeTex" begin

	@testset "acute accents" begin
		@test encodeTex("á") == "\\'a"
		@test encodeTex("Á") == "\\'A"
		@test encodeTex("é") == "\\'e"
		@test encodeTex("É") == "\\'E"
		@test encodeTex("í") == "\\'i"
		@test encodeTex("Í") == "\\'I"
		@test encodeTex("ó") == "\\'o"
		@test encodeTex("Ó") == "\\'O"
		@test encodeTex("ú") == "\\'u"
		@test encodeTex("Ú") == "\\'U"
		@test encodeTex("ý") == "\\'y"
		@test encodeTex("Ý") == "\\'Y"
	end

	@testset "grave accents" begin
		@test encodeTex("à") == "\\`a"
		@test encodeTex("À") == "\\`A"
		@test encodeTex("è") == "\\`e"
		@test encodeTex("È") == "\\`E"
		@test encodeTex("ì") == "\\`i"
		@test encodeTex("Ì") == "\\`I"
		@test encodeTex("ò") == "\\`o"
		@test encodeTex("Ò") == "\\`O"
		@test encodeTex("ù") == "\\`u"
		@test encodeTex("Ù") == "\\`U"
	end

	@testset "circumflex accents" begin
		@test encodeTex("â") == "\\^a"
		@test encodeTex("Â") == "\\^A"
		@test encodeTex("ê") == "\\^e"
		@test encodeTex("Ê") == "\\^E"
		@test encodeTex("î") == "\\^i"
		@test encodeTex("Î") == "\\^I"
		@test encodeTex("ô") == "\\^o"
		@test encodeTex("Ô") == "\\^O"
		@test encodeTex("û") == "\\^u"
		@test encodeTex("Û") == "\\^U"
	end

	@testset "diaeresis / umlaut" begin
		@test encodeTex("ä") == "\\\"a"
		@test encodeTex("Ä") == "\\\"A"
		@test encodeTex("ë") == "\\\"e"
		@test encodeTex("Ë") == "\\\"E"
		@test encodeTex("ï") == "\\\"i"
		@test encodeTex("Ï") == "\\\"I"
		@test encodeTex("ö") == "\\\"o"
		@test encodeTex("Ö") == "\\\"O"
		@test encodeTex("ü") == "\\\"u"
		@test encodeTex("Ü") == "\\\"U"
		@test encodeTex("ÿ") == "\\\"y"
	end

	@testset "tilde" begin
		@test encodeTex("ã") == "\\~a"
		@test encodeTex("Ã") == "\\~A"
		@test encodeTex("ñ") == "\\~n"
		@test encodeTex("Ñ") == "\\~N"
		@test encodeTex("õ") == "\\~o"
		@test encodeTex("Õ") == "\\~O"
	end

	@testset "caron (háček)" begin
		@test encodeTex("č") == "\\v{c}"
		@test encodeTex("Č") == "\\v{C}"
		@test encodeTex("š") == "\\v{s}"
		@test encodeTex("Š") == "\\v{S}"
		@test encodeTex("ž") == "\\v{z}"
		@test encodeTex("Ž") == "\\v{Z}"
		@test encodeTex("ř") == "\\v{r}"
		@test encodeTex("Ř") == "\\v{R}"
		@test encodeTex("ľ") == "\\v{l}"
		@test encodeTex("Ľ") == "\\v{L}"
		# fallback for chars not in the explicit table
		@test encodeTex("ť") == "\\v{t}"
		@test encodeTex("ň") == "\\v{n}"
		@test encodeTex("ď") == "\\v{d}"
	end

	@testset "macron" begin
		@test encodeTex("ā") == "\\=a"
		@test encodeTex("Ā") == "\\=A"
		@test encodeTex("ē") == "\\=e"
		@test encodeTex("Ē") == "\\=E"
		@test encodeTex("ī") == "\\=i"
		@test encodeTex("Ī") == "\\=I"
		@test encodeTex("ō") == "\\=o"
		@test encodeTex("Ō") == "\\=O"
		@test encodeTex("ū") == "\\=u"
		@test encodeTex("Ū") == "\\=U"
	end

	@testset "breve" begin
		@test encodeTex("ă") == "\\u{a}"
		@test encodeTex("Ă") == "\\u{A}"
		@test encodeTex("ğ") == "\\u{g}"
		@test encodeTex("Ğ") == "\\u{G}"
	end

	@testset "double acute" begin
		@test encodeTex("ő") == "\\H{o}"
		@test encodeTex("Ő") == "\\H{O}"
		@test encodeTex("ű") == "\\H{u}"
		@test encodeTex("Ű") == "\\H{U}"
	end

	@testset "ogonek" begin
		@test encodeTex("ą") == "\\k{a}"
		@test encodeTex("Ą") == "\\k{A}"
		@test encodeTex("ę") == "\\k{e}"
		@test encodeTex("Ę") == "\\k{E}"
	end

	@testset "dot above" begin
		@test encodeTex("ż") == "\\.{z}"
		@test encodeTex("Ż") == "\\.{Z}"
		@test encodeTex("ė") == "\\.{e}"
		@test encodeTex("Ė") == "\\.{E}"
	end

	@testset "cedilla" begin
		@test encodeTex("ç") == "\\c{c}"
		@test encodeTex("Ç") == "\\c{C}"
	end

	@testset "ligatures and special letters" begin
		@test encodeTex("æ") == "\\ae{}"
		@test encodeTex("Æ") == "\\AE{}"
		@test encodeTex("ø") == "\\o{}"
		@test encodeTex("Ø") == "\\O{}"
		@test encodeTex("å") == "\\aa{}"
		@test encodeTex("Å") == "\\AA{}"
		@test encodeTex("ł") == "\\l{}"
		@test encodeTex("Ł") == "\\L{}"
		@test encodeTex("ß") == "\\ss{}"
	end

	@testset "punctuation" begin
		@test encodeTex("—") == "---"
		@test encodeTex("–") == "--"
		@test encodeTex("“") == "``"
		@test encodeTex("”") == "''"
	end

	@testset "no-op on plain ASCII" begin
		@test encodeTex("hello world") == "hello world"
		@test encodeTex("") == ""
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "decodeTex/encodeTex round-trip" begin

	samples = [
		# acute
		"á", "Á", "é", "É", "í", "Í", "ó", "Ó", "ú", "Ú", "ý", "Ý",
		# grave
		"à", "À", "è", "È", "ì", "Ì", "ò", "Ò", "ù", "Ù",
		# circumflex
		"â", "Â", "ê", "Ê", "î", "Î", "ô", "Ô", "û", "Û",
		# diaeresis
		"ä", "Ä", "ë", "Ë", "ï", "Ï", "ö", "Ö", "ü", "Ü", "ÿ",
		# tilde
		"ã", "Ã", "ñ", "Ñ", "õ", "Õ",
		# caron (explicit table entries)
		"č", "Č", "š", "Š", "ž", "Ž", "ř", "Ř", "ľ", "Ľ",
		# caron (fallback path)
		"ť", "ň", "ď",
		# macron
		"ā", "Ā", "ē", "Ē", "ī", "Ī", "ō", "Ō", "ū", "Ū",
		# breve
		"ă", "Ă", "ğ", "Ğ",
		# double acute
		"ő", "Ő", "ű", "Ű",
		# ogonek
		"ą", "Ą", "ę", "Ę",
		# dot above
		"ż", "Ż", "ė", "Ė",
		# cedilla
		"ç", "Ç",
		# ligatures
		"æ", "Æ", "ø", "Ø", "å", "Å", "ł", "Ł", "ß",
		# punctuation
		"—", "–",
	]
	for ch ∈ samples
		@test decodeTex(encodeTex(ch)) == ch
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "decodeTex tolerates braces and whitespace" begin

	# extra / nested grouping braces around accent macros
	@test decodeTex("{{\\'a}}") == "á"
	@test decodeTex("{ \\'a }") == "á"
	@test decodeTex("{{\\\"o}}") == "ö"

	# no-argument letter macros, regardless of trailing {} or wrapping braces
	@test decodeTex("\\l") == "ł"
	@test decodeTex("\\l{}") == "ł"
	@test decodeTex("{\\l}") == "ł"
	@test decodeTex("\\l ") == "ł "
	@test decodeTex("\\ss") == "ß"
	@test decodeTex("{\\ss}") == "ß"
	@test decodeTex("\\ae") == "æ"

	# journal macros (not no-arg letter macros) must survive for later expansion
	@test decodeTex("\\aap") == "\\aap"
	@test decodeTex("\\apj") == "\\apj"

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "ampersand: bibtex \\& <-> utf-8 &" begin

	@test decodeTex("A\\&A") == "A&A"
	@test encodeTex("A&A") == "A\\&A"
	@test decodeTex(encodeTex("A&A")) == "A&A"
	@test decodeTex("http://x.org/a?b=1\\&c=2") == "http://x.org/a?b=1&c=2"
	@test encodeTex("http://x.org/a?b=1&c=2") == "http://x.org/a?b=1\\&c=2"

end


# ----------------------------------------------------------------------------------------------- #

# ----------------------------------------------------------------------------------------------- #
#
@testset "ensuremath is unwrapped into plain math" begin

	# the common case: a single symbol macro in a title or keyword
	@test decodeTex("\\ensuremath{\\beta}") == "\$\\beta\$"
	@test decodeTex("The \\ensuremath{\\beta} Pictoris disk") == "The \$\\beta\$ Pictoris disk"
	@test decodeTex("\\ensuremath{\\gamma}-ray burst") == "\$\\gamma\$-ray burst"
	@test decodeTex("\\ensuremath{\\alpha} and \\ensuremath{\\omega}") == "\$\\alpha\$ and \$\\omega\$"

	# the argument is brace-balanced, so inner groups survive
	@test decodeTex("\\ensuremath{\\frac{a}{b}}") == "\$\\frac{a}{b}\$"
	@test decodeTex("\\ensuremath{\\{a\\}}") == "\$\\{a\\}\$"

	# whitespace before and inside the argument is tolerated
	@test decodeTex("\\ensuremath { \\beta }") == "\$\\beta\$"

	# unbraced form: the argument is the macro token that follows
	@test decodeTex("\\ensuremath\\beta") == "\$\\beta\$"
	@test decodeTex("\\ensuremath \\beta") == "\$\\beta\$"

	# an empty argument is dropped rather than left as an empty math region
	@test decodeTex("\\ensuremath{}") == ""
	@test decodeTex("\\ensuremath{   }") == ""

	# only the outermost occurrence introduces delimiters
	@test decodeTex("a\\ensuremath{b\\ensuremath{c}}d") == "a\$bc\$d"

	# inside an existing math region the wrapper is only removed
	@test decodeTex("\$\\ensuremath{\\beta}\$") == "\$\\beta\$"
	@test decodeTex("\$\$\\ensuremath{\\beta}\$\$") == "\$\$\\beta\$\$"

	# malformed or unrelated input is left untouched
	@test decodeTex("\\ensuremath{\\beta") == "\\ensuremath{\\beta"
	@test decodeTex("\\ensuremath") == "\\ensuremath"
	@test decodeTex("\\ensuremathematics{x}") == "\\ensuremathematics{x}"

	# an escaped dollar is not a math delimiter
	@test decodeTex("\\\$5 \\ensuremath{\\beta}") == "\\\$5 \$\\beta\$"

	# accents elsewhere in the field still decode normally
	@test decodeTex("M\\\"uller \\ensuremath{\\beta}") == "Müller \$\\beta\$"

	# the result is plain ASCII, so writing it back out leaves it as it is
	@test encodeTex(decodeTex("\\ensuremath{\\beta}")) == "\$\\beta\$"

end


# ----------------------------------------------------------------------------------------------- #
