mutable struct Tag
    name::String
end

@trigger '#' ->
    function tag(stream::IO, block::MD)
        withstream(stream) do
            if !startswith(stream, '#')
                return nothing
            end
            if startswith(stream, "#") || startswith(stream, ' ')
                return nothing
            end
            tagbuffer = IOBuffer()
            while !eof(stream) && !startswith(stream, ' ') && !startswith(stream, '\n')
                write(tagbuffer, read(stream, Char))
            end
            return Tag(String(take!(tagbuffer)))
        end
    end

function latexinline(io::IO, tag::Tag) end
