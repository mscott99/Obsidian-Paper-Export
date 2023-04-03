include("utils.jl")

struct State
    parsed_notes::Dict{String,Markdown.MD}
    input_folder::String
    longform_file::String
    metadata::Dict{String,String}
    defined_labels::Vector{String}
    depth::Ref{Int}
    inline::Ref{Bool}
end

function State(parsed_notes::Dict{String,Markdown.MD}, input_folder::String, longform_file::String, metadata=Dict())
    defined_labels = String[]
    return State(parsed_notes, input_folder, longform_file, metadata, defined_labels, Ref(0), Ref(false))
end

function build_latex(state::State; skip_abstract=true)
    main_note = state.parsed_notes[state.longform_file]
    abstract = find_heading_content(main_note, "Abstract", state)

    latex_body = generate_latex(main_note, state; skip_abstract=skip_abstract)

    authors = get(state.metadata, "author", "Author")
    title = get(state.metadata, "title", state.longform_file)

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


function generate_latex(note::Markdown.MD, state::State; skip_abstract::Bool=true)
    latex = ""
    in_abstract = false
    for elem in note.content
        if skip_abstract && isa(elem, Markdown.Header) && typeof(elem).parameters[1] == 1 && join(map(x -> convert_to_latex(x, state), elem.text), " ") == "Abstract"
            in_abstract = true
            continue # skip the abstract header
        elseif skip_abstract && in_abstract && isa(elem, Markdown.Header) && typeof(elem).parameters[1] == 1
            in_abstract = false
        end

        if !(in_abstract && skip_abstract)
            state.inline[] = false
            latex *= convert_to_latex(elem, state)
        end
    end
    return latex
end

function convert_to_latex(elem::Markdown.Paragraph, state::State)
    # Convert Markdown elements to LaTeX
    state.inline[] = true
    join(map(x -> convert_to_latex(x, state::State), elem.content), " ") * "\n"
end


function convert_to_latex(elem::Markdown.Header, state::State)
    state.inline[] = true
    rendered_header_text = join(map(x -> convert_to_latex(x, state::State), elem.text), " ")
    return "\n\\$(typeof(elem).parameters[1] == 1 ? "section" : "subsection"){$rendered_header_text}\n\\label{section:$rendered_header_text}\n"
end

function convert_to_latex(elem::Markdown.Ref, state::State)
    return "\\autoref{$elem.label}"
end

function convert_to_latex(elem::Markdown.Code, state::State)
    return "\\texttt{$(escape_latex(elem.code))}"
end

function convert_to_latex(elem::Markdown.Bold, state::State)
    state.inline[] = true
    return "\\textbf{$(join(map(x -> convert_to_latex(x , state), elem.text), " "))}"
end

function convert_to_latex(elem::Markdown.Italic, state::State)
    state.inline[] = true
    return "\\textit{$(join(map(x -> convert_to_latex(x, state), elem.text), " "))}"
end

function convert_to_latex(elem::Markdown.BlockQuote, state::State)
    state.inline[] = true
    content = join(map(x -> convert_to_latex(x, state::State), elem.content), " ") * "\n"
    return "\\begin{quote}\n$content\\end{quote}"
end

function convert_to_latex(elem::Markdown.List, state::State)
    state.inline[] = true
    return "\\begin{itemize}\n$(join(map(x -> "\\item $(convert_to_latex(x, state))", elem.items), "\n"))\\end{itemize}"
end

function convert_to_latex(elem::Markdown.Link, state::State)
    state.inline[] = true
    if elem.url[1] == '#'
        return "\\autoref{$(elem.url[2:end])}"
    else
        return "\\href{$(elem.url)}{$(join(map(x -> convert_to_latex(x, state), elem.text), " "))}"
    end
end

convert_to_latex(elem, state::State) = "NOT IMPLEMENTED: $(typeof(elem))"

convert_to_latex(elem::Markdown.HorizontalRule, state::State) = "\\hrulefill\n"

function convert_to_latex(elem::Union{String,SubString}, state::State)
    if (match_obj = match(r"^(lemma|theorem|corollary|definition|remark)::(!?\[\[.*\]\])(.*)", elem)) !== nothing
        return handle_embed_link(match_obj[2], match_obj[1], state) * convert_to_latex(match_obj[3], state)
    else
        latex = replace(elem, r"!\[\[.+?\]\]" => s -> handle_embed_link(s, nothing, state))
        latex = replace(latex, r"\[\[@.+?\]\]" => s -> "\\cite{$(match(r"\[\[@(.+?)\]\]", s)[1])}")
        latex = replace(latex, r"\[\[.+?\]\]" => s -> handle_ref_wikilink(s, state))
        return latex
    end
end

function convert_to_latex(elem::Markdown.LaTeX, state::State)
    if match(r"\\begin{align", elem.formula) !== nothing
        return "\n" * elem.formula * "\n"
    else
        if state.inline[]
            return "\$" * elem.formula * "\$"
        else
            return "\n\\begin{equation*}\n" * strip(elem.formula, '\n') * "\n\\end{equation*}\n"
        end
    end
end

function handle_ref_wikilink(link, state::State)
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

function handle_embed_link(link, environment, state::State)
    if state.depth[] >= 50
        @warn "Maximum depth reached"
        return link
    end

    link_info = extract_link_info(link)
    if link_info === nothing
        return link
    end

    file_name = link_info[:file_name] * ".md"
    file_path = joinpath(state.input_folder, file_name)  # join input_folder and file_name to get full file path
    anchor = link_info[:anchor]

    if !haskey(state.parsed_notes, file_path)
        @warn "Could not find file $file_path"
        return link
    end

    embedded_note = state.parsed_notes[file_path]
    if isnothing(anchor)
        content = generate_latex(embedded_note, state)
    else
        content = find_heading_content(embedded_note, anchor, state)
    end

    environment_anchors = Dict("Proof" => "proof", "Statement" => "lemma", "Remarks" => "remark", "Remark" => "remark")

    if isnothing(environment) && anchor in keys(environment_anchors)
        environment = environment_anchors[anchor]
    end

    label_name = link_info[:file_name]
    if environment in ("remark", "proof")
        label_name = "$environment:" * label_name
    end
    if label_name in state.defined_labels
        @warn "Label $label_name already defined, replacing with a reference"
        return "\\autoref{$label_name}"
    end

    displayed_result_name = ""
    if environment in ("lemma", "theorem", "corollary", "definition")
        displayed_result_name = "[$(link_info[:file_name])]"
    elseif environment == "proof"
        displayed_result_name = "[Proof of~{\\autoref{$(link_info[:file_name])}}]"
    end

    if !isnothing(environment)
        push!(state.defined_labels, label_name)
        return "\n\\begin{$(environment)}$displayed_result_name\n\\label{$label_name}\n$content\n\\end{$environment}\n"
    else
        return content
    end
end

function find_heading_content(note::Markdown.MD, target_heading, state; include_heading=false)
    found_heading = false
    heading_level = 0
    content = ""

    for (i, elem) in enumerate(note.content)
        if isa(elem, Markdown.Header)
            if found_heading && typeof(elem).parameters[1] <= heading_level
                break
            end
            heading_text = join(map(x -> convert_to_latex(x, state), elem.text), " ")
            if heading_text == target_heading
                found_heading = true
                heading_level = typeof(elem).parameters[1]
                if !include_heading
                    continue
                end
            end
        elseif found_heading && elem isa Markdown.HorizontalRule
            break # do not include stuff after the rule at the end of the file.
        end

        if found_heading
            state.inline[] = false
            content *= convert_to_latex(elem, state) * "\n"
        end
    end

    return content
end

