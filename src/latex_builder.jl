include("utils.jl")

function generate_latex_label(file_name, anchor)
    return "$file_name:$anchor"
end

function generate_latex_label(file_name)
    return "$file_name"
end

function build_latex(parsed_notes, input_folder::String, longform_file::String; metadata=Dict())
    main_note = parsed_notes[longform_file]
    abstract = find_heading_content(main_note, "Abstract", parsed_notes, input_folder, 0)
    latex_body = generate_latex(main_note, parsed_notes, input_folder; depth=0, skip_abstract=true)

    document_class = get(metadata, "document_class", "article")
    authors = get(metadata, "authors", "Author")
    title = get(metadata, "title", "Title")
    # TODO remove the content of the abstract from the body.


    return """
\\documentclass{$document_class}
\\usepackage{hyperref}
\\usepackage{amsmath}
\\usepackage{amsthm}
\\usepackage{amssymb}
\\usepackage{biblatex}
\\addbibresource{bibliography.bib}
\\newtheorem{theorem}{Theorem}
\\newtheorem{lemma}[theorem]{Lemma}
\\newtheorem{corollary}[theorem]{Corollary}
\\newtheorem{definition}{Definition}
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

function extract_metadata(note::Markdown.MD)
    metadata = Dict{String,Any}()
    for elem in note.content
        if isa(elem, Markdown.Header) && typeof(elem).parameters[1] == 1
            key = elem.text
            value = elem.content
            metadata[key] = value
        end
    end
    return metadata
end

function generate_latex(note::Markdown.MD, parsed_notes::Dict{String,<:Any}, input_folder; depth::Int=0, skip_abstract::Bool=true)
    latex = ""
    in_abstract = false
    for elem in note.content
        if isa(elem, Markdown.Header) && typeof(elem).parameters[1] == 1
            if join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth), elem.text), " ") == "Abstract"
                in_abstract = true
                continue # skip the abstract header
            elseif in_abstract
                in_abstract = false
            end
        end
        if !in_abstract || !skip_abstract
            latex *= convert_to_latex(elem, parsed_notes, input_folder, depth)
        end
        # isa(elem, Markdown.Link) && occursin(r"!?\[\[(.+?)\]\]", elem.url)
        #    m = match(r"!?\[\[(.+?)\]\]", elem.url)
        #    if m !== nothing
        #        full_anchor = m.captures[1]
        #        file, anchor = split_anchor(full_anchor)
        #        if haskey(parsed_notes, file)
        #            if anchor != ""
        #                embedded_content = find_heading_content(parsed_notes[file], anchor, parsed_notes, input_folder, depth)
        #                latex *= embedded_content
        #            else
        #                latex *= generate_latex(parsed_notes[file], parsed_notes, input_folder; depth=depth + 1)
        #            end
        #        end
        #    end
        #else



    end
    return latex
end

function convert_to_latex(elem, parsed_notes::Dict{String,<:Any}, input_folder::String, depth::Int)
    # Convert Markdown elements to LaTeX
    latex = ""
    if isa(elem, Markdown.Paragraph)
        latex = join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth), elem.content), " ")
    elseif isa(elem, Markdown.Header)
        level = typeof(elem).parameters[1]
        header_text = join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth), elem.text), " ")
        latex_label = generate_latex_label("section", header_text)
        latex = "\n\\$(level == 1 ? "section" : "subsection"){$header_text}\\label{$latex_label}\n"
    elseif isa(elem, Markdown.Ref)
        label = create_autoref_label(elem.label)
        latex = "\\autoref{$label}"
    elseif isa(elem, Markdown.Code)
        latex = "\\texttt{$(escape_latex(elem.code))}"
    elseif isa(elem, Markdown.Bold)
        latex = "\\textbf{$(join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth), elem.text), " "))}"
    elseif isa(elem, Markdown.Italic)
        latex = "\\textit{$(join(map(x -> convert_to_latex(x, parsed_notes, input_folder, depth), elem.text), " "))}"
    elseif isa(elem, Markdown.BlockQuote)
        latex = "\\begin{quote}\n$(generate_latex(elem, parsed_notes, input_folder, depth=depth+1))\\end{quote}"
    elseif isa(elem, Markdown.List)
        latex = "\\begin{itemize}\n$(join(map(x -> "\\item $(generate_latex(x, parsed_notes, input_folder, depth=depth+1))", elem.items), "\n"))\\end{itemize}"
    elseif isa(elem, String)

        if match(r"^(lemma|theorem|corollary|definition)::", elem) !== nothing
            pattern = r"^(lemma|theorem|corollary|definition)::(.*)$"
            match_obj = match(pattern, elem)
            if match_obj !== nothing
                environment = match_obj[1]
                statement = match_obj[2]
                linkinfo = extract_link_info(statement) #assume that what follows lemma:: is a embed link
                latex_label = generate_latex_label(linkinfo[:file_path])
                latex = "\n\\begin{$(environment)}\n\\label{$latex_label}\n$(handle_embed_link(statement, parsed_notes, input_folder, depth+1; added_within_environment=true))\n\\end{$(environment)}\n"
            end
        else
            latex = replace(elem, r"!\[\[.+?\]\]" => s -> handle_embed_link(s, parsed_notes, input_folder, depth + 1))
            latex = replace(latex, r"\[\[@.+?\]\]" => s -> "\\cite{$(match(r"\[\[@(.+?)\]\]", s)[1])}")
            latex = replace(latex, r"\[\[.+?\]\]" => s -> handle_ref_wikilink(s))
        end
    elseif isa(elem, Markdown.LaTeX)
        if match(r"\begin{align", elem.formula) !== nothing
            latex = elem.formula
        else
            latex = "\$" * elem.formula * "\$"
        end
    end
    return latex
end

function handle_ref_wikilink(link)
    link_info = extract_link_info(link)
    if link_info === nothing
        @warn "Could not extract link info from $link"
        return link
    end

    if link_info[:anchor] == ""
        return "\\autoref{$(generate_latex_label(link_info[:file_path]))}"
    else
        return "\\autoref{$(generate_latex_label(link_info[:file_path], link_info[:anchor]))}"
    end
end

function handle_embed_link(link, parsed_notes::Dict{String,<:Any}, input_folder, depth::Int; added_within_environment=false)
    link_info = extract_link_info(link)
    if link_info === nothing
        return link
    end
    file_name = link_info[:file_path] * ".md"
    file_path = joinpath(input_folder, file_name)  # join input_folder and file_name to get full file path
    anchor = link_info[:anchor]

    if !haskey(parsed_notes, file_path)
        return link
    end
    if isempty(anchor)
        label = create_autoref_label(file_path)
        return "\\autoref{$label}"
    else
        embedded_note = parsed_notes[file_path]
        if isnothing(anchor)
            return embedded_note.content
        end

        content = find_heading_content(embedded_note, anchor, parsed_notes, input_folder, depth + 1)

        if anchor == "Statement" && !added_within_environment
            return "\n\\begin{lemma}\n$content\n\\end{lemma}\n"
        elseif anchor == "Proof" && !added_within_environment
            return "\n\\begin{proof}\n$content\n\\end{proof}\n"
        else
            return content
        end
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
        end
        if found_heading
            content *= convert_to_latex(elem, parsed_notes, input_folder, depth + 1) * "\n"
        end
    end

    return content
end

