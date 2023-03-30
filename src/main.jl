include("obsidian_parser.jl")
include("latex_builder.jl")

function main(input_folder::String, longform_file::String, output_file::String)
    metadata = extract_metadata(joinpath(input_folder, longform_file))
    parsed_notes = parse_obsidian_folder(input_folder)
    latex = build_latex(parsed_notes, input_folder, longform_file; metadata)
    write(output_file, latex)
end

if length(ARGS) != 3
    println("Usage: julia main.jl <input_folder> <longform_file> <output_file>")
else
    main(args[1], args[2], args[3])
end
#main("./examples", "./examples/main_note.md", "./examples/output/output.tex")
main("../../myVault/Zettelkasten/", "../../myVault/Zettelkasten/Journal Sample Longform.md", "./examples/output/journal1/Export Journal Output.tex")