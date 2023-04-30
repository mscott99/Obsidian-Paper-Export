mutable struct Wikilink
    address::String
    header::String
    displaytext::String
    embed::Bool
    attribute::String
    Wikilink(address::String, header::String, displaytext::String, embed::Bool, attribute::String="") =
        new(address, header, displaytext, embed, attribute)
end

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
                if !eof(stream) && peek(stream) == '@'
                    return nothing # handled by citation
                end
                wikicontent = wikilink_content(stream, block, false)
                return wikicontent
            end
        end
    end


@breaking true ->
    function embedwikilink(stream::IO, block::MD)
        withstream(stream) do
            skipwhitespace(stream)
            startswith(stream, "![[") || return false
            content = wikilink_content(stream, block, true)
            isnothing(content) && return false

            #figure support
            if occursin(r"\.png|\.jpg|\.jpeg|\.gif|\.svg|\.pdf|\.tiff?$", content.address)
                push!(block, Figure(content.address, content.displaytext))
                return true
            end

            push!(block, content)
            return true
        end
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
    return lowercase(elt.address)
end

function unroll(elt::Wikilink, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
    if !elt.embed
        return [elt]
    end

    if (elt.address, elt.header) in globalstate[:environments]
        @warn "Repeated embed detected for $(elt.address) $(elt.header), reverting it to reference."
        elt.embed = false
        return [Paragraph([elt])]
    end
    if depth >= globalstate[:maxdepth]
        @warn "Maximum depth reached for $(elt.address) $(elt.header), reverting it to reference."
        elt.embed = false
        return [Paragraph([elt])] # non-embed wikilinks are inline.
    end

    filepath = joinpath(notesfolder, elt.address * ".md")
    if !isfile(filepath)
        @warn "File $filepath does not exist"
        elt.embed = false
        return [Paragraph([elt])]
    end

    f = open(filepath)
    filecontent = parse(f, yamlparser)
    close(f)

    if elt.header != ""
        filecontent = find_heading_content(filecontent, elt.header)
        if isnothing(filecontent)
            @warn "File $filepath does not contain heading $(elt.header), reverting to reference."
            elt.embed = false
            return [Paragraph([elt])]
        end
    end

    currentfile = elt.address
    unrolledcontent = []
    if filecontent[1] isa YAMLHeader
        popfirst!(filecontent)
    end
    for element in filecontent.content
        push!(unrolledcontent, unroll(element, notesfolder, currentfile, globalstate, depth + 1)...)
    end
    return unrolledcontent
end

function show(io::IO, link::Wikilink)
    if link.embed
        print(io, "!")
    end
    print(io, "[[$(link.address)")
    if !isempty(link.header)
        print(io, "#$(link.header)")
    end
    if !isempty(link.displaytext)
        print(io, "|$(link.displaytext)")
    end
    print(io, "]]")
    return
end

# fallback when no config.
latexinline(io::IO, obj, config) = latexinline(io, obj)

function latexinline(io::IO, link::Wikilink)
    if link.embed
        show(io, link)
        return
    end
    if link.displaytext |> isempty
        print(io, "\\autoref{$(lowercase(link.address))}")
        return
    else
        println(io, "$(link.displaytext)\\ref{$(lowercase(link.address))}")
        return
    end
end

function latexinline(io::IO, link::Wikilink; refs_with_display_text=false, kwargs...)
    if link.embed
        show(io, link)
        return
    end
    if link.displaytext |> isempty
        if link.header == "Proof"
            # print(io, "\\autoref{proof:$(lowercase(link.address))}")
            print(io, "\\hyperlink{proof:$(lowercase(link.address))}{the proof}")
            return
        end
        print(io, "\\autoref{$(lowercase(link.address))}")
        return
    end
    print(io, "$(link.displaytext)")
    if refs_with_display_text
        print(io, "\\ref{$(lowercase(link.address))}")
    end
    return
end

function latex(io::IO, link::Wikilink; refs_with_display_text=false, kwargs...)
    if link.embed
        show(io, link)
        println(io)
        return
    end
    if link.displaytext |> isempty
        if link.header == "Proof"
            println(io, "\\autoref{proof:$(lowercase(link.address))}")
            return
        end
        println(io, "\\autoref{$(lowercase(link.address))}")
        return
    end
    print(io, "$(link.displaytext)")
    if refs_with_display_text
        print(io, "\\ref{$(lowercase(link.address))}")
    end
    println(io)
end


# function latex(io::IO, link::Wikilink; refs_with_display_text=false, kwargs...)
#     if link.embed
#         show(io, link)
#         println(io)
#         return
#     end
#     if link.displaytext |> isempty
#         println(io, "\\autoref{$(lowercase(link.address))}")
#         return
#     else
#         print(io, "$(link.displaytext)")
#         if refs_with_display_text
#             print(io, "\\ref{$(lowercase(link.address))}")
#         end
#         println(io)
#         return
#     end
# end

# function latex(io::IO, link::Wikilink)
#     if link.embed
#         println(io, "![[$(link.address)]]")
#         return
#     end
#     if link.displaytext |> isempty
#         println(io, "\\autoref{$(link.address)}")
#         return
#     else
#         println(io, "$(link.displaytext)\\ref{$(link.address)}")
#         return
#     end
# end