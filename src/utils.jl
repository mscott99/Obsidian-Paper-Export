function wrapblock(f, io, env, displaycontent)
    println(io, "\\begin{", env, "}[$displaycontent]")
    f()
    println(io, "\\end{", env, "}")
end

function extract_link_info(link)
    match_obj = match(r"!?\[\[([^#\|]+)(?:#([^\|]+?))?(?:\|(.+))?\]\]", link)
    if match_obj === nothing
        @warn "no link found for extraction for $link"
        return nothing
    end
    return Dict(
        :file_name => match_obj[1],
        :anchor => match_obj[2],
        :display_name => match_obj[3]
    )
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

function split_anchor(full_anchor::String)
    parts = split(full_anchor, '#', keepempty=false)
    if length(parts) == 1
        return parts[1], ""
    else
        return parts[1], '#' * parts[2]
    end
end
