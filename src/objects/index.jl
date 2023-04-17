using Markdown: Markdown, @flavor, github_paragraph, @breaking, MD, startswith, withstream, readuntil, LaTeX, @trigger, parse_inline_wrapper, skipwhitespace, showrest, config, parse, HorizontalRule, Paragraph, Header
using Markdown: blockquote, list, hashheader, fencedcode, github_table, blocktex, footnote, github_paragraph, escapes, tex, asterisk_italic, underscore_italic, underscore_bold, inline_code, wrapblock
import Markdown: latex, latexinline, wrapblock, wrapinline

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

@flavor obsidian [blockquote, environment, displaytex, list, hashheader, horizontalrule, embedwikilink, obsidianfencedcode, github_table, footnote, github_paragraph, tag, displayinlinetex, inlinetex, inline_embedwikilink, wikilink, escapes, asterisk_italic, underscore_italic, underscore_bold, inline_code]


#code for testing parsing

#stream = open("./examples/main_note.md", "r")
#obj = parse(stream, yamlparser; flavor=obsidian)

#true == true