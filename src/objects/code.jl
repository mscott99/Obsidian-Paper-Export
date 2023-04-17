# Need a new version to make math blocks display type.
@breaking true ->
    function obsidianfencedcode(stream::IO, block::MD)
        withstream(stream) do
            startswith(stream, "~~~", padding=true) || startswith(stream, "```", padding=true) || return false
            skip(stream, -1)
            ch = read(stream, Char)
            trailing = strip(readline(stream))
            flavor = lstrip(trailing, ch)
            n = 3 + length(trailing) - length(flavor)

            # inline code block
            ch in flavor && return false

            buffer = IOBuffer()
            while !eof(stream)
                line_start = position(stream)
                if startswith(stream, string(ch)^n)
                    if !startswith(stream, string(ch))
                        if flavor == "math"
                            push!(block, DisplayLaTeX(String(take!(buffer)) |> chomp))
                        else
                            push!(block, Code(flavor, String(take!(buffer)) |> chomp))
                        end
                        return true
                    else
                        seek(stream, line_start)
                    end
                end
                write(buffer, readline(stream, keep=true))
            end
            return false
        end
    end
