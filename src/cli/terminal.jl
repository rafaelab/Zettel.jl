# ----------------------------------------------------------------------------------------------- #
#
@doc """
	chooseKeyFromTty(suggested, existing; output)

Interactively choose a citation key from the terminal.
If no interactive terminal is detected, return the suggested key.
Otherwise, prompt the user to accept the suggested key or enter a custom key.
Validate the custom key against the expected pattern and check for conflicts with existing keys.
Return the final chosen key.

# Input
- `suggested` [`AbstractString`]: the suggested citation key to accept or override.
- `existing` [`Set{String}`]: set of existing keys in the library to check for conflicts.
- `output` [`IO`]: the IO stream to use for prompts and messages (default: stdout).

# Output
- The chosen citation key as a string.
"""
function chooseKeyFromTty(suggested::AbstractString, existing::Set{String}; output::IO = stdout)
	if ! (stdin isa Base.TTY) || ! ispath("/dev/tty")
		println(output, "No interactive terminal detected; accepting suggested key '$(suggested)'.")
		return String(suggested)
	end

	open("/dev/tty", "r+") do tty
		println(tty, "Press Enter to accept the suggested key, or type a custom key.")
		while true
			print(tty, "Key [", suggested, "]: ")
			flush(tty)

			reply = try
				readline(tty)
			catch
				""
			end

			key = strip(reply)
			if isempty(key)
				return String(suggested)
			end
			if ! validGeneratedKeyPattern(key)
				println(tty, "Invalid key format. Expected lowercase(authorSurname)YearX, e.g. einstein1905a.")
				continue
			end

			if key ∈ existing
				println(tty, "Key '", key, "' already exists in the library.")
				continue
			end

			return key
		end
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	acceptFileKeyFromTty(fileKey; output)

Prompt on TTY to accept/reject a file-derived key that does not match the expected pattern.
Returns `true` when accepted, `false` otherwise.
"""
function acceptFileKeyFromTty(fileKey::AbstractString; output::IO = stdout)
	if ! (stdin isa Base.TTY) || ! ispath("/dev/tty")
		println(output, "No interactive terminal detected; rejecting key inferred from file: '$(fileKey)'.")
		return false
	end

	open("/dev/tty", "r+") do tty
		while true
			print(tty, "Use file-derived key '", fileKey, "' anyway? [y/N]: ")
			flush(tty)

			reply = try
				readline(tty)
			catch
				""
			end
			
			answer = lowercase(strip(reply))
			if isempty(answer) || answer ∈ ("n", "no")
				return false
			elseif answer ∈ ("y", "yes")
				return true
			end
		end
	end
end

# ----------------------------------------------------------------------------------------------- #
