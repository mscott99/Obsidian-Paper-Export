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