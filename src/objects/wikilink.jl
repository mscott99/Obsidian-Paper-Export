mutable struct Wikilink
    address::String
    embed::Bool
    header::String
    displaytext::String
    attribute::String
    Wikilink(address::String, embed::Bool, header::String="", displaytext::String="", attribute::String="") =
        new(address, embed, header, displaytext, attribute)
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
    return Wikilink(String(take!(namebuffer)), embed, String(take!(headerbuffer)), String(take!(displaybuffer)))
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

    filepath = find_file(notesfolder, elt.address* ".md")
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

function latexinline(io::IO, link::Wikilink; refs_with_display_text=false, kwargs...)
    if link.embed
        show(io, link)
        return
    end

    # Display link
    if !isempty(link.displaytext)
        print(io, "$(link.displaytext)")
        if refs_with_display_text
            print(io, "\\ref{$(get_location_label(link.address, link.header))}")
        end
        return
    end

    # Local header link. Header links follow a different format.
    if link.address |> isempty
        print(io, "\\autoref{sec:$(lowercase(escape_label(link.header)))}")
        return
    end

    # Proof link
    if link.header == "Proof"
        print(io, "\\hyperlink{$(get_location_label(link.address, link.header))}{the proof}")
        return
    end

    # Reference link
    print(io, "\\autoref{$(get_location_label(link.address, link.header))}")
    return
end

"""Only deals with Wikilinks that are left over from previous processing."""
function latex(io::IO, link::Wikilink; refs_with_display_text=false, kwargs...)
    latexinline(io, link; refs_with_display_text=refs_with_display_text, kwargs...)
    println(io)
end
