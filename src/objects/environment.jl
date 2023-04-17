mutable struct Environment
    environmentname::String
    content
    label::String
end
function Environment(environmentname::String, content::MD)
    return Environment(environmentname, content, "")
end

import Markdown: latex
function latex(io::IO, env::Environment)
    if env.environmentname == "proof"
        targetlabel = match(r"(?:[^\:]+):(.*)", env.label)[1]
        wrapblock(io, env.environmentname, "Proof of \\autoref{$targetlabel}") do
            if env.label != ""
                println(io, "\\label{$(env.label)}")
            end
            latex(io, env.content)
        end
    else
        wrapblock(io, env.environmentname) do
            if env.label != ""
                println(io, "\\label{$(env.label)}")
            end
            latex(io, env.content)
        end
    end
    println(io)
end

function environmentinfo(stream::IO)
    withstream(stream) do
        envbuffer = IOBuffer()
        while !eof(stream)
            startswith(stream, ' ') && return false
            startswith(stream, "::") && break
            write(envbuffer, read(stream, Char))
        end
        environmentname = String(take!(envbuffer))
        skipwhitespace(stream)
        return environmentname
    end
end

@breaking true ->
    function environment(stream::IO, block::MD)
        withstream(stream) do
            envbuffer = IOBuffer()
            while true
                eof(stream) && return false
                startswith(stream, ' ') && return false
                startswith(stream, '\n') && return false
                startswith(stream, "::") && break
                write(envbuffer, read(stream, Char))
            end
            environmentname = String(take!(envbuffer))
            skipwhitespace(stream)
            content = MD(config(block))
            push!(block, Environment(environmentname, content))

            #embedded environment

            if startswith(stream, '!', eat=false)
                embedwikilink(stream, content) && return true
                skip(stream, -1)
            end

            #explicite environment
            contentbuffer = IOBuffer()
            while !eof(stream) && !startswith(stream, "::$environmentname")
                write(contentbuffer, read(stream, Char))
            end
            seek(contentbuffer, 0)
            while parse(contentbuffer, content)
            end
            return true
        end
    end

function unroll(elt::Environment, notesfolder::String, currentfile::String, globalstate::Dict)
    if elt.content[1] isa Wikilink && elt.content[1].embed
        elt.label = wikilink_label(elt.content[1])
    end
    outarray = []
    for element in elt.content.content
        push!(outarray, unroll(element, notesfolder, currentfile, globalstate)...)
    end
    elt.content.content = outarray
    push!(globalstate[:environments], elt.label)
    return [elt]
end