
mutable struct DisplayLaTeX
    formula::String
end

struct LabeledHeader{l}
    label::String
    header::Header{l}
end

function latex(io::IO, header::LabeledHeader)
    latex(io, header.header)
    wrapinline(io, "label") do
        print(io, header.label)
    end
    println(io)
end

function latex(io::IO, tex::DisplayLaTeX)
    if match(r"\\begin{align", tex.formula) !== nothing
        println(io, tex.formula)
    else
        println(io, "\$\$", tex.formula, "\$\$")
    end
end

function latexinline(io::IO, tex::DisplayLaTeX) # compensate for display is inline
    println(io)
    latex(io, tex)
end

mutable struct InlineLaTeX
    formula::String
end

function latexinline(io::IO, tex::InlineLaTeX)
    print(io, '$', tex.formula, '$')
end

show(io::IO, tex::InlineLaTeX) =
    print(io, '$', tex.formula, '$')

latex(io::IO, tex::InlineLaTeX) =
    print(io, '$', tex.formula, '$')

show(io::IO, tex::DisplayLaTeX) =
    print(io, "\$\$", tex.formula, "\$\$")

latex(io::IO, tex::LaTeX) =
    (match(r"\\begin{align", tex.formula) !== nothing && return println(io, tex.formula)) || println(io, "\$\$", tex.formula, "\$\$")

# Found in its own paragraph
@breaking true ->
    function displaytex(stream::IO, block::MD)
        withstream(stream) do
            startswith(stream, "\$\$", padding=true) || return false
            mathcontent = readuntil(stream, "\$\$"; newlines=true)
            isnothing(mathcontent) && return false
            push!(block, DisplayLaTeX(strip(mathcontent)))
            return true
        end
    end

# found inline
@trigger '$' ->
    function inlinetex(stream::IO, md::MD)
        if startswith(stream, '$') && peek(stream, Char) != '$'
            # display math
            formula = readuntil(stream, "\$")
            return isnothing(formula) ? nothing : InlineLaTeX(strip(formula))
        end
    end

@trigger '$' ->
    function displayinlinetex(stream::IO, md::MD)
        if startswith(stream, "\$\$")
            formula = readuntil(stream, "\$\$"; newlines=true)
            return isnothing(formula) ? nothing : DisplayLaTeX(strip(formula))
        else
            return nothing
        end
    end

# Try to support lemmas in paragraphs. Seems pretty hard
#=
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
=#

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
    wrapblock(io, env.environmentname) do
        if env.label != ""
            println(io, "\\label{$(env.label)}")
        end
        latex(io, env.content)
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

mutable struct Wikilink
    address::String
    header::String
    displaytext::String
    embed::Bool
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

#=
@trigger '!' ->
    function embedwikilink(stream::IO, block::MD)
        withstream(stream) do
            startswith(stream, "[[") || return # I don't know why there is no "!" here.
            return wikilink_content(stream, block, true)
        end
    end
=#

@breaking true ->
    function embedwikilink(stream::IO, block::MD)
        withstream(stream) do
            startswith(stream, "![[") || return false# I don't know why there is no "!" here.
            content = wikilink_content(stream, block, true)
            isnothing(content) && return false
            push!(block, content)
            return true
        end
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

mutable struct Citation
    address::String
end

latexinline(io::IO, citation::Citation) = print(io, "\\cite{$(citation.address)}")

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

using YAML

mutable struct YAMLHeader
    content::Dict{Any,Any}
end

@flavor obsidian [environment, displaytex, list, hashheader, horizontalrule, embedwikilink, obsidianfencedcode, github_table, footnote, github_paragraph, tag, displayinlinetex, inlinetex, inline_embedwikilink, wikilink, escapes, asterisk_italic, underscore_italic, underscore_bold, inline_code]

"Positional parser, parses the YAML header."
function yamlparser(stream::IO, block::MD)
    withstream(stream) do
        startswith(stream, "---") || return false
        buffer = IOBuffer()
        while !eof(stream)
            startswith(stream, "---") && break
            write(buffer, readline(stream, keep=true))
        end
        push!(block, YAMLHeader(YAML.load(String(take!(buffer)))))
        return true
    end
end

import Markdown.parse
function parse(stream::Core.IO, initialparser::Core.Function; flavor=obsidian)
    isa(flavor, Symbol) && (flavor = flavors[flavor])
    markdown = MD(flavor)
    initialparser(stream, markdown)
    while parse(stream, markdown, flavor)
    end
    return markdown
end

stream = open("./examples/main_note.md", "r")
obj = parse(stream, yamlparser; flavor=obsidian)

true == true

