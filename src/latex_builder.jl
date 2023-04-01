include("utils.jl")

function build_latex(parsed_notes, input_folder::String, longform_file::String; metadata=Dict())

    main_note = parsed_notes[longform_file]
    abstract = find_heading_content(main_note, "Abstract", parsed_notes, input_folder, 0)
    latex_body = generate_latex(main_note, parsed_notes, input_folder; depth=0, skip_abstract=true)

    authors = get(metadata, "author", "Author")
    title = get(metadata, "title", longform_file)
    # TODO remove the content of the abstract from the body.


    return """
\\documentclass{article}
\\input{header}
\\input{preamble.sty}
\\addbibresource{bibliography.bib}

\\title{$title}
\\author{$authors}

\\begin{document}
\\maketitle
\\begin{abstract}
$abstract
\\end{abstract}
$latex_body
\\printbibliography
\\end{document}
"""
end



function generate_latex(note::Markdown.MD, parsed_notes::Dict{String,<:Any}, input_folder; depth::Int=0, skip_abstract::Bool=true)
    latex = ""
    in_abstract = false
    for elem in note.content
        if skip_abstract && isa(elem, Markdown.Header) && typeof(elem).parameters[1] == 1 && join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth), elem.text), " ") == "Abstract"
            in_abstract = true
            continue # skip the abstract header
        elseif skip_abstract && in_abstract && isa(elem, Markdown.Header) && typeof(elem).parameters[1] == 1
            in_abstract = false
        end

        if !in_abstract || !skip_abstract
            latex *= convert_to_latex(elem, parsed_notes, input_folder, depth)
        end
    end
    return latex
end

function convert_to_latex(elem::Markdown.Paragraph, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    # Convert Markdown elements to LaTeX
    join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth, true), elem.content), " ") * "\n"
end


function convert_to_latex(elem::Markdown.Header, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    rendered_header_text = join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth, true), elem.text), " ")
    return "\n\\$(typeof(elem).parameters[1] == 1 ? "section" : "subsection"){$rendered_header_text}\n\\label{section:$rendered_header_text}\n"
end

function convert_to_latex(elem::Markdown.Ref, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    return "\\autoref{$elem.label}"
end

function convert_to_latex(elem::Markdown.Code, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    return "\\texttt{$(escape_latex(elem.code))}"
end

function convert_to_latex(elem::Markdown.Bold, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    return "\\textbf{$(join(map(x -> convert_to_latex(x , parsed_notes, input_folder, depth, true), elem.text), " "))}"
end

function convert_to_latex(elem::Markdown.Italic, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    return "\\textit{$(join(map(x -> convert_to_latex(x , parsed_notes, input_folder, depth, true), elem.text), " "))}"
end

function convert_to_latex(elem::Markdown.BlockQuote, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    return "\\begin{quote}\n$(generate_latex(elem, parsed_notes, input_folder, depth=depth+1))\\end{quote}"
end

function convert_to_latex(elem::Markdown.List, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    return "\\begin{itemize}\n$(join(map(x -> "\\item $(generate_latex(x, parsed_notes, input_folder, depth=depth+1))", elem.items), "\n"))\\end{itemize}"
end

function convert_to_latex(elem::Markdown.Link, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    if elem.url[1] == '#'
        return "\\autoref{$(elem.url[2:end])}"
    else
        return "\\href{$(elem.url)}{$(join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth, true), elem.text), " "))}"
    end
end

function convert_to_latex(elem, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    return "NOT IMPLEMENTED: $(typeof(elem))"
end

convert_to_latex(elem::Markdown.HorizontalRule, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false) = "\\hrulefill"

function convert_to_latex(elem::Union{String,SubString}, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    if (match_obj = match(r"^(lemma|theorem|corollary|definition|remark)::(!?\[\[.*\]\])(.*)", elem)) !== nothing
        environment = match_obj[1]
        statement = match_obj[2]
        linkinfo = extract_link_info(statement) #assume that what follows lemma:: is a embed link
        latex_label = linkinfo[:file_name]
        displayed_result_name = environment in ("lemma", "theorem", "corollary", "definition") ? "[$(linkinfo[:file_name])]" : ""
        return "\n\\begin{$(environment)}$displayed_result_name\n\\label{$latex_label}\n$(handle_embed_link(statement, parsed_notes, input_folder, depth+1; added_within_environment=true))\n\\end{$(environment)}\n$(convert_to_latex(match_obj[3], parsed_notes, input_folder, depth, inline))\n"
    else
        latex = replace(elem, r"!\[\[.+?\]\]" => s -> handle_embed_link(s, parsed_notes, input_folder, depth + 1))
        latex = replace(latex, r"\[\[@.+?\]\]" => s -> "\\cite{$(match(r"\[\[@(.+?)\]\]", s)[1])}")
        latex = replace(latex, r"\[\[.+?\]\]" => s -> handle_ref_wikilink(s))
        return latex
    end
end

function convert_to_latex(elem::Markdown.LaTeX, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int, inline=false)
    if match(r"\\begin{align", elem.formula) !== nothing
        return "\n" * elem.formula * "\n"
    else
        if inline
            return "\$" * elem.formula * "\$"
        else
            return "\n\\begin{equation*}\n" * elem.formula * "\n\\end{equation*}\n"
        end
    end
end

function handle_ref_wikilink(link)
    link_info = extract_link_info(link)
    if link_info === nothing
        @warn "Could not extract link info from $link"
        return link
    end
    if !isnothing(link_info[:display_name])
        return "$(link_info[:display_name])\\ref{$(link_info[:file_name])}"
    end
    return "\\autoref{$(link_info[:file_name])}"
end

function handle_embed_link(link, parsed_notes::Dict{String,<:Any}, input_folder, depth::Int; added_within_environment=false)
    if depth >= 50
        @warn "Maximum depth reached"
        return link
    end
    link_info = extract_link_info(link)
    if link_info === nothing
        return link
    end
    label_name = link_info[:file_name]
    file_name = link_info[:file_name] * ".md"
    file_path = joinpath(input_folder, file_name)  # join input_folder and file_name to get full file path
    anchor = link_info[:anchor]

    if !haskey(parsed_notes, file_path)
        return link
    end

    embedded_note = parsed_notes[file_path]
    if isnothing(anchor)
        return generate_latex(embedded_note, parsed_notes, input_folder, depth=depth + 1)
    end

    content = find_heading_content(embedded_note, anchor, parsed_notes, input_folder, depth + 1)

    if anchor == "Statement" && !added_within_environment
        return "\n\\begin{lemma}[$label_name]\n\\label{$label_name}\n$content\n\\end{lemma}\n"
    elseif anchor == "Proof" && !added_within_environment
        return "\n\\begin{proof}[Proof of~{\\autoref{$label_name}}]\n\\label{proof:$(label_name)}\n$content\n\\end{proof}\n"
    elseif !isnothing(match(r"Remarks!", anchor)) && !added_within_environment
        return "\n\\begin{remark}\n\\label{remark:$(label_name)}\n$content\n\\end{remark}\n"
    else
        return content
    end
end

function find_heading_content(note::Markdown.MD, target_heading, parsed_notes::Dict, input_folder, depth::Int; include_heading=false)
    found_heading = false
    heading_level = 0
    content = ""

    for (i, elem) in enumerate(note.content)
        if isa(elem, Markdown.Header)
            if found_heading && typeof(elem).parameters[1] <= heading_level
                break
            end
            heading_text = join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth), elem.text), " ")
            if heading_text == target_heading
                found_heading = true
                heading_level = typeof(elem).parameters[1]
                if !include_heading
                    continue
                end
            end
        elseif isa(elem, Markdown.HorizontalRule) && found_heading
            break # do not include stuff after the rule at the end of the file.
        end
        if found_heading
            content *= convert_to_latex(elem, parsed_notes, input_folder, depth + 1) * "\n"
        end
    end

    return content
end

