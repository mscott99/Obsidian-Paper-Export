using YAML

include("./objects/index.jl")
include("utils.jl")
include("unroll.jl")

function main(input_folder::String, longform_file::String, outputfolder::String, configfile="./examples/config.YAML"; texfilesfolder="./latex_files/", imgfilefolder="Files")
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

    metadata, unrolledcontent = unrolledmainfile(input_folder, longform_file; filefolder=imgfilefolder, outfolder=outputfolder)
    abstract = find_heading_content(unrolledcontent, "Abstract"; removecontent=true)
    appendix = find_heading_content(unrolledcontent, "Appendix"; removecontent=true)
    merge!(metadata, YAML.load_file(configfile))
    @info appendix
    f = open(joinpath(outputfolder, "output.tex"), write=true, create=true)
    write(
        f,
        "\\documentclass{article}
\\input{header}
\\input{preamble.sty}
\\addbibresource{bibliography.bib}
\\title{$(get(metadata, "title", escape_latex(longform_file)))}
\\author{$(get(metadata,"author", "Author"))}
\\begin{document}
\\maketitle
")
    if !isnothing(abstract)
        write(f, "\\abstract{")
        latex(f, abstract)
        write(f, "}\n")
    end
    latex(f, unrolledcontent, metadata)
    write(
        f,
        "\\printbibliography
\\end{document}"
    )
    #end
    close(f)
    if !isnothing(appendix)
        f = open(joinpath(outputfolder, "supp.tex"), write=true, create=true)
        write(
            f,
            "\\documentclass{article}
\\input{header}
\\input{preamble.sty}
\\addbibresource{bibliography.bib}
\\title{$(get(metadata, "appendix_title", "Appendix"))}
\\author{$(get(metadata,"author", "Author"))}
\\begin{document}
\\maketitle
")
        latex(f, appendix, metadata)
        write(
            f,
            "\\printbibliography
\\end{document}"
        )
        close(f)
    end
    @info "Export Completed!"
end


#=
if !(length(ARGS) in [3, 4])
    println("Usage: julia main.jl <input_folder> <longform_file> <output_file>[ <config_file>]")
    exit()
end


if length(ARGS) == 4
    scriptconfig = YAML.load_file(ARGS[4])
    if scriptconfig["ignore_quotes"]
        @info "Ignoring quotes from config"
        eval(quote
            import Markdown: BlockQuote
            function latex(io::IO, md::BlockQuote)
                return ""
            end
        end)
    end
end

main(ARGS...)
=#
scriptconfig = YAML.load_file("./examples/config.YAML")
if scriptconfig["ignore_quotes"]
    @info "Ignoring quotes from config"
    eval(quote
        import Markdown: BlockQuote
        function latex(io::IO, md::BlockQuote)
            return ""
        end
    end)
end
main("../../myVault/Zettelkasten/", "Longform Conference Uneven Sampling", "./examples/output/Uneven_Sampling_Conference/")
#main("../../Ik-Vault/Zettelkasten/", "Sub-Gaussian McDiarmid Inequality and Classification on the Sphere", "./examples/output/project555_output/")
#main("./examples/", "main_note", "./examples/output/example_output/"; texfilesfolder="./latex_files/")
#main("../../myVault/Zettelkasten/", "Journal Sample Longform", "./examples/output/journal1/")
#main("./myVault/Zettelkasten/", "./myVault/Zettelkasten/Uneven Sampling Journal Version Longform.md", "./export_markdown/Obsidian\ Paper\ Export/examples/output/uneven_journal/"; output_file_name="Uneven Sampling Journal Version.tex", img_folder_name="Files")