using Zettel

function main(args::Vector{String})
	return Zettel.zettelCLI(; args = args)
end

(@main)(args) = main(args)
