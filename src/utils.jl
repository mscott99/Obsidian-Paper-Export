import Markdown: wrapblock

function wrapblock(f, io, env, displaycontent)
    println(io, "\\begin{", env, "}[$displaycontent]")
    f()
    println(io, "\\end{", env, "}")
end

import Markdown: wrapinline
function wrapinline(f, io, cmd, options)
    print(io, "\\", cmd, "[$options]{")
    f()
    print(io, "}")
end

function replaceinfile(file, string, replacestring)
    f = open(file, "r+")
    while !eof(f)
        if startswith(f, string; eat=false)
            mark(f)
            buf = IOBuffer()
            startswith(f, string; eat=true) # replace the anchor
            write(buf, f)
            seekstart(buf)
            reset(f)
            latex(f, replacestring)
            write(f, buf)
            close(f)
            return
        end
        read(f, Char)
    end
    @warn "template had no occurence of: $string"
    close(f)
end

function reduceallheaders(content::MD)
    outcontent = MD(config(content))
    for (i, elt) in enumerate(content.content)
        if elt isa Union{Header,LabeledHeader}
            level = elt isa Header ? typeof(elt).parameters[1] : typeof(elt.header).parameters[1]
            if level == 1
                @warn "Cannot reduce a heading of level 1, will skip. Heading name: $(repr(elt.text))"
                push!(outcontent, elt)
            else
                newheader = elt isa Header ? Header(level - 1, elt.text) : LabeledHeader(elt.label, elt.header, level - 1)
                push!(outcontent, newheader)
            end
        else
            push!(outcontent, elt)
        end
    end
    return outcontent
end
function reduceallheaders(content::Nothing)
    return nothing
end

function escape_latex(text::String)
    replacements = (
        '\\' => "\\textbackslash{}",
        '{' => "\\{",
        '}' => "\\}",
        '&' => "\\&",
        '#' => "\\#",
        '^' => "\\textasciicircum{}",
        '_' => "\\_",
        '~' => "\\textasciitilde{}",
        '%' => "\\%",
        '"' => "\\\"",
        '\'' => "\\'"
    )
    return replace(text, replacements...)
end
