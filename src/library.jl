export
	ZettelLibrary,
	loadLibrary,
	saveLibrary


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	ZettelLibrary

A collection of [`ZettelEntry`](@ref) objects, indexed by their citation keys.

# Fields
- `entries` [`OrderedDict{String, ZettelEntry}`]: ordered mapping of citation keys to entries
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
@inline Base.length(lib::ZettelLibrary) = length(lib.entries)


@doc """
	keys(lib)

Return the citation keys stored in a `ZettelLibrary`.
"""
@inline Base.keys(lib::ZettelLibrary) = keys(lib.entries)


@doc """
	values(lib)

Return all [`ZettelEntry`](@ref) objects stored in a `ZettelLibrary`.
"""
@inline Base.values(lib::ZettelLibrary) = values(lib.entries)


@doc """
	getindex(lib, key)

Return the [`ZettelEntry`](@ref) with the given citation key.
"""
@inline Base.getindex(lib::ZettelLibrary, key::AbstractString) = lib.entries[key]


@doc """
	haskey(lib, key)

Return `true` if the library contains an entry with the given citation key.
"""
@inline Base.haskey(lib::ZettelLibrary, key::AbstractString) = haskey(lib.entries, key)


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


@doc """
	pop!(lib, key)

Remove and return the [`ZettelEntry`](@ref) with the given citation key.
"""
Base.pop!(lib::ZettelLibrary, key::AbstractString) = pop!(lib.entries, key)



@doc """
	iterate(lib[, state])

Iterate over the entries in a `ZettelLibrary`.
"""
Base.iterate(lib::ZettelLibrary) = iterate(values(lib.entries))
Base.iterate(lib::ZettelLibrary, state) = iterate(values(lib.entries), state)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	show(io, lib)

Print a brief summary of a `ZettelLibrary`.
"""
Base.show(io::IO, lib::ZettelLibrary) = begin
	print(io, @sprintf("ZettelLibrary containing %d entries.\n", length(lib)))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	sort(lib)

Return a new [`ZettelLibrary`](@ref) with entries sorted alphabetically by citation key.

# Input
- `lib` [`ZettelLibrary`]: the library

# Output
- A new [`ZettelLibrary`](@ref) with entries in ascending key order.
"""
function Base.sort(lib::ZettelLibrary)
	sortedKeys = sort(collect(keys(lib.entries)))
	d = OrderedDict{String, ZettelEntry}()
	for k ∈ sortedKeys
		d[k] = lib.entries[k]
	end
	return ZettelLibrary(d)
end

# ----------------------------------------------------------------------------------------------- #
#
@doc """
    sort!(lib)

Sort a [`ZettelLibrary`](@ref) in-place by citation key in ascending order.

# Input
- `lib` [`ZettelLibrary`]: the library

# Output
- The input `lib` with entries reordered alphabetically by key.
"""
function Base.sort!(lib::ZettelLibrary)
	sortedKeys = sort(collect(keys(lib.entries)))
	entriesBackup = copy(lib.entries)
	
	empty!(lib.entries)
	for k ∈ sortedKeys
		lib.entries[k] = entriesBackup[k]
	end

	return lib
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	loadLibrary(filename)

Load a [`ZettelLibrary`](@ref) from `filename`, inferring the format from the file extension.
Supported extensions: `.json`, `.yaml`, `.yml`, `.bib`.

# Input
- `filename` [`AbstractString`]: path to the bibliography file.

# Output
- A [`ZettelLibrary`](@ref) parsed from `filename`.
"""
function loadLibrary(filename::AbstractString)
	if ! isfile(filename)
		throw(ArgumentError("File not found: $(filename)"))
	end
	return readBibliography(identifyBibliographyFormat(filename), filename)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	saveLibrary(lib, filename)

Save a [`ZettelLibrary`](@ref) to `filename`, inferring the format from the file extension.
Supported extensions: `.json`, `.yaml`, `.yml`, `.bib`.

# Input
- `lib` [`ZettelLibrary`]: the library to save
- `filename` [`AbstractString`]: destination file path.

# Output
- `nothing`.
"""
function saveLibrary(lib::ZettelLibrary, filename::AbstractString)
	writeBibliography(identifyBibliographyFormat(filename), lib, filename)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
