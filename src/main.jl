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

if length(ARGS) != 3
    println("Usage: julia main.jl <input_folder> <longform_file> <output_file>")
else
    main(args[1], args[2], args[3])
end

main("../../Ik-Vault/Zettelkasten/", "../../Ik-Vault/Zettelkasten/Sub-Gaussian McDiarmid Inequality and Classification on the Sphere.md", "./examples/output/project555_output"; output_file_name="main.tex")
#main("./examples/", "./examples/main_note.md", "./examples/output/example_output")
#main("../../myVault/Zettelkasten/", "../../myVault/Zettelkasten/Journal Sample Longform.md", "./examples/output/journal1/Export Journal Output.tex")
#main("./myVault/Zettelkasten/", "./myVault/Zettelkasten/Uneven Sampling Journal Version Longform.md", "./export_markdown/Obsidian\ Paper\ Export/examples/output/uneven_journal/"; output_file_name="Uneven Sampling Journal Version.tex", img_folder_name="Files")