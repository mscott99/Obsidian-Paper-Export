using Markdown: @flavor, github_paragraph, @breaking, MD, startswith, withstream, readuntil, LaTeX, @trigger, parse_inline_wrapper, skipwhitespace, showrest, config, parse, HorizontalRule, Paragraph, Header
using Markdown: list, hashheader, fencedcode, github_table, blocktex, footnote, github_paragraph, escapes, tex, asterisk_italic, underscore_italic, underscore_bold, inline_code, wrapblock
using Markdown
using Markdown: *
using Markdown: wrapinline
import Markdown: latex, latexinline

include("obsidian_parser.jl")
include("latex_builder.jl")

function main(input_folder::String, longform_file_path::String, output_folder::String; output_file_name::String="output.tex", img_folder_name::String="Files")
    metadata = extract_metadata(joinpath(longform_file_path))
    parsed_notes = parse_obsidian_folder(joinpath(input_folder))
    start_state = State(parsed_notes, input_folder, output_folder, longform_file_path;
        metadata=metadata,
        img_folder_name=img_folder_name,
        output_file_name=output_file_name)
    latex = build_latex(start_state)
    write(joinpath(output_folder, output_file_name), latex)
end

include("obsidian_flavor.jl")
include("unroll.jl")

function main(input_folder::String, longform_file::String, outputfolder::String; texfilesfolder="./latex_files/")

    metadata, unrolledcontent = unrolledmainfile(input_folder, longform_file)
    if !isdir(outputfolder)
        mkdir(outputfolder)
    end
    if isfile(joinpath(outputfolder, "output.tex"))
        rm(joinpath(outputfolder, "output.tex"))
    end
    if !isempty(texfilesfolder)
        if isfile(joinpath(texfilesfolder, "preamble.sty")) && !isfile(joinpath(outputfolder, "preamble.sty"))
            cp(joinpath(texfilesfolder, "preamble.sty"), joinpath(outputfolder, "preamble.sty"))
        end
        if isfile(joinpath(texfilesfolder, "header.tex")) && !isfile(joinpath(outputfolder, "header.tex"))
            cp(joinpath(texfilesfolder, "header.tex"), joinpath(outputfolder, "header.tex"))
        end
        if isfile(joinpath(texfilesfolder, "bibliography.bib")) && !isfile(joinpath(outputfolder, "bibliography.bib"))
            cp(joinpath(texfilesfolder, "bibliography.bib"), joinpath(outputfolder, "bibliography.bib"))
        end
    end

    f = open(joinpath(outputfolder, "output.tex"), write=true, create=true)
    write(
        f,
        "\\documentclass{article}
\\input{header}
\\input{preamble.sty}
\\addbibresource{bibliography.bib}
\\title{$(get(metadata, "title", longform_file))}
\\author{$(get(metadata,"author", "Author"))}
")
    latex(f, unrolledcontent)
    write(
        f,
        "\\printbibliography
\\end{document}"
    )
    #end
    close(f)
    #parsed_notes = parse_obsidian_folder(joinpath(input_folder))
    #start_state = State(parsed_notes, input_folder, longform_file, metadata)
    #latex = build_latex(start_state)
    #write(output_file, latex)
end


#Markdown.@trigger

if length(ARGS) != 3
    println("Usage: julia main.jl <input_folder> <longform_file> <output_file>")
else
    main(args[1], args[2], args[3])
end

main("../../Ik-Vault/Zettelkasten/", "../../Ik-Vault/Zettelkasten/Sub-Gaussian McDiarmid Inequality and Classification on the Sphere.md", "./examples/output/project555_output"; output_file_name="main.tex")
#main("./examples/", "./examples/main_note.md", "./examples/output/example_output")
main("../../Ik-Vault/Zettelkasten/", "Sub-Gaussian McDiarmid Inequality and Classification on the Sphere", "./examples/output/project555_output/")
#main("./examples/", "main_note", "./examples/output/"; texfilesfolder="./latex_files/")
#main("../../myVault/Zettelkasten/", "../../myVault/Zettelkasten/Journal Sample Longform.md", "./examples/output/journal1/Export Journal Output.tex")
#main("./myVault/Zettelkasten/", "./myVault/Zettelkasten/Uneven Sampling Journal Version Longform.md", "./export_markdown/Obsidian\ Paper\ Export/examples/output/uneven_journal/"; output_file_name="Uneven Sampling Journal Version.tex", img_folder_name="Files")