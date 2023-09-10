using YAML
using Markdown: startswith

include("./objects/index.jl")
include("utils.jl")
include("unroll.jl")

function generate_latex(input_folder_path::String, longform_file_name::String, outputfolder_path::String; texfilesfolder="./latex_files/", imgfilefolder="Files", main_doc_template="", kwargs...)
  if !isdir(outputfolder_path)
    mkdir(outputfolder_path)
  end
  if isfile(joinpath(outputfolder_path, "output.tex"))
    rm(joinpath(outputfolder_path, "output.tex"))
  end
  if !isempty(texfilesfolder)
    if isfile(joinpath(texfilesfolder, "preamble.sty")) && !isfile(joinpath(outputfolder_path, "preamble.sty"))
      cp(joinpath(texfilesfolder, "preamble.sty"), joinpath(outputfolder_path, "preamble.sty"))
    end
    if isfile(joinpath(texfilesfolder, "header.tex")) && !isfile(joinpath(outputfolder_path, "header.tex"))
      cp(joinpath(texfilesfolder, "header.tex"), joinpath(outputfolder_path, "header.tex"))
    end
    if isfile(joinpath(texfilesfolder, "bibliography.bib")) && !isfile(joinpath(outputfolder_path, "bibliography.bib"))
      cp(joinpath(texfilesfolder, "bibliography.bib"), joinpath(outputfolder_path, "bibliography.bib"))
    end
  end
  metadata, unrolledcontent = unrolledmainfile(input_folder_path, longform_file_name; filefolder=imgfilefolder, outfolder=outputfolder_path)
  abstract = find_heading_content(unrolledcontent, "Abstract"; removecontent=true)
  appendix = find_heading_content(unrolledcontent, "Appendix"; removecontent=true)
  appendix = isnothing(appendix) ? nothing : reduceallheaders(appendix)

  body = reduceallheaders(find_heading_content(unrolledcontent, "Body"))
  if isnothing(body)
    body = unrolledcontent
  end

  # merge!(metadata, YAML.load_file(configfile_path))
  f = open(joinpath(outputfolder_path, "output.tex"), write=true, create=true)

  main_doc_template = isempty(main_doc_template) ? get(metadata, "main_doc_template", "") : main_doc_template
  if !isempty(main_doc_template)
    cp(main_doc_template, joinpath(outputfolder_path, "output.tex"), force=true)
    if !isnothing(abstract)
      replaceinfile(joinpath(outputfolder_path, "output.tex"), "\$abstract\$", abstract)
    end
    replaceinfile(joinpath(outputfolder_path, "output.tex"), "\$body\$", body)
    if !isnothing(appendix)
      replaceinfile(joinpath(outputfolder_path, "output.tex"), "\$appendix\$", appendix)
    end
  else
    # TODO Change this to a default template file in the project.
    write(
      f,
      "\\documentclass{article}
\\input{header}
\\input{preamble.sty}
\\addbibresource{bibliography.bib}
\\title{$(get(metadata, "title", escape_latex(longform_file_name)))}
\\author{$(get(metadata,"author", "Author"))}
\\begin{document}
\\maketitle
")
    if !isnothing(abstract)
      write(f, "\\abstract{")
      latex(f, abstract)
      write(f, "}\n")
    end
    latex(f, body, metadata)
    write(
      f,
      "\\printbibliography
\\end{document}"
    )
    #end
    close(f)
  end
  if !isnothing(appendix)
    f = open(joinpath(outputfolder_path, "supp.tex"), write=true, create=true)
    #=        write(
                f,
                "\\documentclass{article}
    \\input{header}
    \\input{preamble.sty}
    \\addbibresource{bibliography.bib}
    \\title{$(get(metadata, "appendix_title", "Appendix"))}
    \\author{$(get(metadata,"author", "Author"))}
    \\begin{document}
    \\maketitle
    ")=#
    latex(f, appendix, metadata)
    #=write(
        f,
        "\\printbibliography
    \\end{document}"
    )=#
    close(f)
  end
  @info "Export Completed!"
end

function checkConfigIsValid(config_dict::Dict{Symbol,Any})
  required_keys = [:input_folder_path, :longform_file_name, :output_folder_path]
  for key in required_keys
    if !haskey(config_dict, key)
      @error "Field $key not found in config file"
    end
  end
end


if length(ARGS) == 1
  scriptconfig = YAML.load_file(ARGS[1])
  if scriptconfig["ignore_quotes"]
    @info "Ignoring quotes from config"
    eval(quote
      import Markdown: BlockQuote
      function latex(io::IO, md::BlockQuote)
        return ""
      end
    end)
  end
  scriptconfig = Dict(Symbol(key) => value for (key, value) in scriptconfig)
  checkConfigIsValid(scriptconfig)
  generate_latex(scriptconfig[:input_folder_path], scriptconfig[:longform_file_name], scriptconfig[:output_folder_path]; scriptconfig...)
  exit(1)
end

#main("../../Ik-Vault/Zettelkasten/", "Sub-Gaussian McDiarmid Inequality and Classification on the Sphere", "./examples/output/project555_output/")
#main("./examples/", "main_note", "./examples/output/example_output/"; texfilesfolder="./latex_files/")
#main("../../myVault/Zettelkasten/", "Journal Sample Longform", "./examples/output/journal1/")
#main("./myVault/Zettelkasten/", "./myVault/Zettelkasten/Uneven Sampling Journal Version Longform.md", "./export_markdown/Obsidian\ Paper\ Export/examples/output/uneven_journal/"; output_file_name="Uneven Sampling Journal Version.tex", img_folder_name="Files")
#main("../../myVault/Zettelkasten/", "Longform Conference Uneven Sampling", "./testout");

