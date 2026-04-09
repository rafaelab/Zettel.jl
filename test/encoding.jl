# ----------------------------------------------------------------------------------------------- #
#
@testset "decodeTex" begin

	@testset "accented characters" begin
		@test decodeTex("\\'e") == "é"
		@test decodeTex("\\'E") == "É"
		@test decodeTex("\\`a") == "à"
		@test decodeTex("\\^o") == "ô"
		@test decodeTex("\\\"u") == "ü"
		@test decodeTex("\\~n") == "ñ"
		@test decodeTex("\\c{c}") == "ç"
		@test decodeTex("\\v{s}") == "š"
		@test decodeTex("\\=a") == "ā"
		@test decodeTex("\\H{o}") == "ő"
	end

	@testset "ligatures and special letters" begin
		@test decodeTex("\\ae{}") == "æ"
		@test decodeTex("\\AE{}") == "Æ"
		@test decodeTex("\\o{}") == "ø"
		@test decodeTex("\\O{}") == "Ø"
		@test decodeTex("\\aa{}") == "å"
		@test decodeTex("\\l{}") == "ł"
		@test decodeTex("\\ss{}") == "ß"
	end

	@testset "punctuation" begin
		@test decodeTex("---") == "—"
		@test decodeTex("--") == "–"
		@test decodeTex("``") == "\u201C"
		@test decodeTex("''") == "\u201D"
	end

	@testset "embedded in string" begin
		@test decodeTex("Schr\\\"odinger") == "Schrödinger"
		@test decodeTex("Caf\\'e au lait") == "Café au lait"
		@test decodeTex("na\\\"ive") == "naïve"
		@test decodeTex("Zur Elektrodynamik bewegter K{\\\"o}rper") == "Zur Elektrodynamik bewegter Körper"
		@test decodeTex("S\\v{t}astn\\'y") == "Sťastný"
		@test decodeTex("Sakall{\\i}, {\\.I}.") == "Sakallı, İ."
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
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "encodeTex" begin

	@testset "accented characters" begin
		@test encodeTex("é") == "\\'e"
		@test encodeTex("É") == "\\'E"
		@test encodeTex("à") == "\\`a"
		@test encodeTex("ô") == "\\^o"
		@test encodeTex("ü") == "\\\"u"
		@test encodeTex("ñ") == "\\~n"
		@test encodeTex("ç") == "\\c{c}"
		@test encodeTex("š") == "\\v{s}"
		@test encodeTex("ť") == "\\v{t}"
		@test encodeTex("ā") == "\\=a"
		@test encodeTex("ő") == "\\H{o}"
	end

	@testset "ligatures and special letters" begin
		@test encodeTex("æ") == "\\ae{}"
		@test encodeTex("Æ") == "\\AE{}"
		@test encodeTex("ø") == "\\o{}"
		@test encodeTex("Ø") == "\\O{}"
		@test encodeTex("å") == "\\aa{}"
		@test encodeTex("ł") == "\\l{}"
		@test encodeTex("ß") == "\\ss{}"
	end

	@testset "punctuation" begin
		@test encodeTex("—") == "---"
		@test encodeTex("–") == "--"
		@test encodeTex("\u201C") == "``"
		@test encodeTex("\u201D") == "''"
	end

	@testset "no-op on plain ASCII" begin
		@test encodeTex("hello world") == "hello world"
		@test encodeTex("") == ""
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "decodeTex/encodeTex round-trip" begin

	samples = ["é", "ü", "ñ", "ç", "š", "ť", "ő", "ł", "ß", "æ", "ø", "å", "ā", "à", "ô", "—", "–"]
	for ch ∈ samples
		@test decodeTex(encodeTex(ch)) == ch
	end

end


# ----------------------------------------------------------------------------------------------- #
