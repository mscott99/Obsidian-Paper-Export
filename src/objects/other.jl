# Try to support lemmas in paragraphs. Seems pretty hard
# This file is not imported
@breaking true ->
function envinsentence(stream::IO, block::MD) #liar function, it splits and walks back
    withstream(stream) do
        linecontains(stream, "::") || return false
        lastsentence = ""
        while !eof(stream)
            word = ""
            lastpos = position(stream)-1
            while !eof(stream)
                if startswith(stream,' ')
                    word *= ' '
                    break
                end
                if startswith(stream, '\n', eat=false)
                    break
                end
                if startswith(stream, "::")
                    seek(stream, lastpos)
                    if block.content[end] isa Markdown.Paragraph
                        push!(block.content[end], lastsentence)
                    push!(block.content[end], )
                    block.content[end]
                end
                read(stream, Char)
            end
            lastsentence *= word
        end
    end
end