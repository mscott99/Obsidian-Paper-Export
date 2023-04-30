using Markdown: Code, Markdown, @flavor, github_paragraph, @breaking, MD, startswith, withstream, readuntil, LaTeX, @trigger, parse_inline_wrapper, skipwhitespace, showrest, config, parse, HorizontalRule, Paragraph, Header
using Markdown: blockquote, list, hashheader, fencedcode, github_table, blocktex, footnote, github_paragraph, escapes, tex, asterisk_italic, asterisk_bold, underscore_italic, underscore_bold, inline_code, wrapblock, skipblank
import Markdown: latex, latexinline, wrapblock, wrapinline, parse_inline_wrapper

include("figure.jl")
include("environment.jl")
include("code.jl")
include("latex.jl")
include("tag.jl")
include("wikilink.jl")
include("YAML_header.jl")
include("horizontalrule.jl")
include("header.jl")
include("figure.jl")
include("quotes.jl")
include("citations.jl")

function latex(io::IO, md::Paragraph; kwargs...)
    for mdc in md.content
        latexinline(io, mdc; kwargs...)
    end
    println(io)
    println(io)
end

function latex(io::IO, content::Vector; kwargs...)
    for c in content
        latex(io, c; kwargs...)
    end
end

latex(io::IO, md::MD; kwargs...) = latex(io, md.content; kwargs...)

# default
latex(io::IO, md, config) = latex(io, md)


@flavor obsidian [blockquote, environment, displaytex, list, hashheader, horizontalrule, embedwikilink, obsidianfencedcode, github_table, footnote, github_paragraph, tag, displayinlinetex, inlinetex, inline_embedwikilink, citation, wikilink, escapes, asterisk_italic, asterisk_bold, underscore_italic, underscore_bold, inline_code, doublequote]


#code for testing parsing

#stream = open("./examples/main_note.md", "r")
#obj = parse(stream, yamlparser; flavor=obsidian)

#true == true