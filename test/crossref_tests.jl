# ----------------------------------------------------------------------------------------------- #
@testset "Crossref fetch" begin
	payload = """{"status":"ok","message":{"DOI":"10.1000/test","title":["Example"]}}"""
	record = fetchCrossrefJson("10.1000/test"; fetcher = _ -> payload)
	@test record["DOI"] == "10.1000/test"
	@test record["title"][1] == "Example"
	@test_throws ArgumentError fetchCrossrefJson("10.1000/test"; fetcher = _ -> "{")
	@test_throws ArgumentError fetchCrossrefJson("10.1000/test"; fetcher = _ -> "{\"status\":\"ok\"}")
end
