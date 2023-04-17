@breaking true ->
    function horizontalrule(stream::IO, block::MD)
        withstream(stream) do
            n, rule = 0, ' '
            for char in readeach(stream, Char)
                char == '\n' && break
                isspace(char) && continue
                if n == 0 || char == rule
                    rule = char
                    n += 1
                else
                    return false
                end
            end
            is_hr = (n ≥ 3 && rule in "*-")
            is_hr && push!(block, HorizontalRule())
            return is_hr
        end
    end
