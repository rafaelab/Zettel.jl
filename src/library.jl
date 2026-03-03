# ----------------------------------------------------------------------------------------------- #
#
@doc """
	ZettelLibrary

A collection of [`ZettelEntry`](@ref) objects, indexed by their citation keys.

# Fields
- `entries::OrderedDict{String,ZettelEntry}`: ordered mapping of citation keys to entries
"""
struct ZettelLibrary
	entries::OrderedDict{String, ZettelEntry}
end


ZettelLibrary() = ZettelLibrary(OrderedDict{String, ZettelEntry}())

ZettelLibrary(entries::Vector{ZettelEntry}) = begin
	d = OrderedDict{String, ZettelEntry}()
	for entry ∈ entries
		d[entry.key] = entry
	end
	return ZettelLibrary(d)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	length(lib)

Return the number of entries in a `ZettelLibrary`.
"""
Base.length(lib::ZettelLibrary) = length(lib.entries)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	keys(lib)

Return the citation keys stored in a `ZettelLibrary`.
"""
Base.keys(lib::ZettelLibrary) = keys(lib.entries)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	values(lib)

Return all [`ZettelEntry`](@ref) objects stored in a `ZettelLibrary`.
"""
Base.values(lib::ZettelLibrary) = values(lib.entries)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getindex(lib, key)

Return the [`ZettelEntry`](@ref) with the given citation key.
"""
Base.getindex(lib::ZettelLibrary, key::AbstractString) = lib.entries[key]


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	haskey(lib, key)

Return `true` if the library contains an entry with the given citation key.
"""
Base.haskey(lib::ZettelLibrary, key::AbstractString) = haskey(lib.entries, key)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	push!(lib, entry)

Insert a [`ZettelEntry`](@ref) into the library. 
If an entry with the same key already exists it is overwritten.
"""
function Base.push!(lib::ZettelLibrary, entry::ZettelEntry)
	lib.entries[entry.key] = entry
	return lib
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	pop!(lib, key)

Remove and return the [`ZettelEntry`](@ref) with the given citation key.
"""
Base.pop!(lib::ZettelLibrary, key::AbstractString) = pop!(lib.entries, key)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	iterate(lib[, state])

Iterate over the entries in a `ZettelLibrary`.
"""
function Base.iterate(lib::ZettelLibrary, state = iterate(values(lib.entries)))
	isnothing(state) && return nothing
	entry, inner_state = state
	return (entry, iterate(values(lib.entries), inner_state))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	show(io, lib)

Print a brief summary of a `ZettelLibrary`.
"""
function Base.show(io::IO, lib::ZettelLibrary)
	n = length(lib)
	print(io, @sprintf("ZettelLibrary containing %d entries.\n", n))
end


# ----------------------------------------------------------------------------------------------- #
