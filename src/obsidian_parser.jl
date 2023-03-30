using Markdown
using Glob

function parse_obsidian_folder(input_folder::String)
    file_paths = glob("*.md", input_folder)
    return Dict(fp => parse_obsidian_file(fp) for fp in file_paths)
end

function parse_obsidian_file(file_path::String)
    content = read(file_path, String)
    return Markdown.parse(content)
end



