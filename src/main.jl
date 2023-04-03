include("obsidian_parser.jl")
include("latex_builder.jl")

function main(input_folder::String, longform_file::String, output_file::String)
    metadata = extract_metadata(joinpath(longform_file))
    parsed_notes = parse_obsidian_folder(joinpath(input_folder))
    start_state = State(parsed_notes, input_folder, longform_file, metadata)
    latex = build_latex(start_state)
    write(output_file, latex)
end

if length(ARGS) != 3
    println("Usage: julia main.jl <input_folder> <longform_file> <output_file>")
else
    main(args[1], args[2], args[3])
end
main("./examples/", "./examples/main_note.md", "./examples/output/output.tex")
#main("../../myVault/Zettelkasten/", "../../myVault/Zettelkasten/Journal Sample Longform.md", "./examples/output/journal1/Export Journal Output.tex")
#main("../../myVault/Zettelkasten/", "../../myVault/Zettelkasten/Uneven Sampling Journal Version Longform.md", "./examples/output/uneven_journal/Export Journal Output.tex")