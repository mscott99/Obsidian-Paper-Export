using Markdown
using Glob
using YAML

function parse_obsidian_file(file_path::String)
    mdlines = readlines(file_path)
    # Check for YAML header
    if length(mdlines) > 0 && mdlines[1] == "---"
        dash_lines = findall(x -> x == "---", mdlines)
        md = join(mdlines[findall(x -> x == "---", mdlines)[2]+1:end], "\n")
    else
        md = read(file_path, String)
    end
    #md = join(mdlines[findall(x -> x == "---", mdlines)[2]+1:end], "\n")
    #content = md
    #content = read(file_path, String)

    #pre_processed = replace(md, r"\$\$\n(.+?)\n\$\$" => s -> "\$\$$(match(r"\$\$\n(.+?)\n\$\$",s)[1])\$\$")
    process_eq(eq) = replace(eq, r"\n+" => "\n") # remove newlines
    pre_processed = replace(md, r"\$\$(?:\s|\n)*(.|\n)+?(?:\s|\n)*\$\$" => s -> "```math\n$(process_eq(match(r"\$\$(?:\s|\n)*((?:.|\n)+?)(?:\s|\n)*\$\$", s)[1]))\n```")

    return Markdown.parse(pre_processed; flavor=:julia)
end

function parse_obsidian_folder(input_folder::String)
    file_paths = glob("*.md", input_folder)
    return Dict(fp => parse_obsidian_file(fp) for fp in file_paths)
end

function extract_metadata(file_path::String)
    mdlines = readlines(file_path)
    if mdlines[1] == "---"
        dash_lines = findall(x -> x == "---", mdlines)
        yaml = join(mdlines[dash_lines[1]:dash_lines[2]], "\n")
        metadata = YAML.load(yaml)
    else
        return Dict()
    end
    # return the metadata dictionary
    return metadata
end
# end of code block



