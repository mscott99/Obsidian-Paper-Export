function extract_link_info(link)
    match_obj = match(r"!?\[\[(.*?)#(.*?)\]\]", link)
    if match_obj |> isnothing
        match_obj = match(r"!?\[\[(.*?)\]\]", link)
        if match_obj |> isnothing
            @warn "Could not extract link info from $link"
            return nothing
        end
        return Dict(
            :file_path => match_obj[1],
            :anchor => ""
        )
    end
    return Dict(
        :file_path => match_obj[1],
        :anchor => match_obj[2]
    )
end

function escape_latex(text::String)
    replacements = Dict(
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
    return replace(text, replacements)
end

function split_anchor(full_anchor::String)
    parts = split(full_anchor, '#', keepempty=false)
    if length(parts) == 1
        return parts[1], ""
    else
        return parts[1], '#' * parts[2]
    end
end
