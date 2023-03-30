include("obsidian_parser.jl")
include("latex_builder.jl")

function main(input_folder::String, longform_file::String, output_file::String)
    parsed_notes = parse_obsidian_folder(input_folder)
    latex = build_latex(parsed_notes, input_folder, longform_file)
    write(output_file, latex)
end

if length(ARGS) != 3
    println("Usage: julia main.jl <input_folder> <longform_file> <output_file>")
else
    main(ARGS[1], ARGS[2], ARGS[3])
end
main("./examples", "./examples/main_note.md", "./examples/output.tex")