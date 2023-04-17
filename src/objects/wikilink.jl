mutable struct Wikilink
    address::String
    header::String
    displaytext::String
    embed::Bool
end

mutable struct Citation
    address::String
end

latexinline(io::IO, citation::Citation) = print(io, "\\cite{$(citation.address)}")

@trigger '!' ->
    function inline_embedwikilink(stream::IO, block::MD)
        withstream(stream) do
            startswith(stream, "![[") || return nothing
            return wikilink_content(stream, block, true)
        end
    end

@trigger '[' ->
    function wikilink(stream::IO, block::MD)
        withstream(stream) do
            if startswith(stream, "[[")
                wikicontent = wikilink_content(stream, block, false)
                if wikicontent.address[1] == '@' # wikilink to pandoc citations.
                    return Citation(wikicontent.address[2:end])
                end
                return wikicontent
            elseif startswith(stream, "[@") # allow for standard pandoc citations
                linkaddress = readuntil(stream, ']')
                return isnothing(linkaddress) ? nothing : Citation(linkaddress)
            end
            return nothing
        end
    end

function latexinline(io::IO, link::Wikilink)
    if link.embed
        print(io, "![[$(link.address)]]")
        return
    end
    if link.displaytext |> isempty
        print(io, "\\autoref{$(link.address)}")
        return
    end
    print(io, "$(link.displaytext)\\autoref{$(link.address)}")
end

function latex(io::IO, link::Wikilink)
    if link.embed
        println(io, "![[$(link.address)]]")
        return
    end
    if link.displaytext |> isempty
        println(io, "\\autoref{$(link.address)}")
        return
    end
    println(io, "$(link.displaytext)\\autoref{$(link.address)}")
end

function wikilink_content(stream::IO, block::MD, embed::Bool)
    namebuffer = IOBuffer()
    headerbuffer = IOBuffer()
    displaybuffer = IOBuffer()
    buffer = namebuffer
    while !eof(stream) && !startswith(stream, "]]")
        if startswith(stream, '|')
            buffer = displaybuffer
        end
        if startswith(stream, '#')
            buffer = headerbuffer
        end
        write(buffer, read(stream, Char))
    end
    return Wikilink(String(take!(namebuffer)), String(take!(headerbuffer)), String(take!(displaybuffer)), embed)
end

function wikilink_label(elt::Wikilink)
    if elt.header |> isempty || elt.header == "Statement"
        return elt.address
    else
        return lowercase(elt.header * ':' * elt.address)
    end
end

function unroll(elt::Wikilink, notesfolder::String, currentfile::String, globalstate::Dict)
    if elt.embed
        if wikilink_label(elt) in globalstate[:environments]
            elt.embed = false
            return [Paragraph([elt])] # non-embed wikilinks are inline.
        end
        filepath = joinpath(notesfolder, elt.address * ".md")
        local filecontent
        if isfile(filepath)
            filecontent = open(filepath) do f
                parse(f, yamlparser)
            end
        else
            @warn "File $filepath does not exist"
            elt.embed = false
            return [Paragraph([elt])]
        end

        if elt.header != ""
            filecontent = find_heading_content(filecontent, elt.header)
        end
        currentfile = elt.address
        unrolledcontent = []
        if filecontent[1] isa YAMLHeader
            popfirst!(filecontent)
        end
        for element in filecontent.content
            push!(unrolledcontent, unroll(element, notesfolder, currentfile, globalstate)...)
        end
        return unrolledcontent
    else
        return [elt]
    end
end