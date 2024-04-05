import Markdown: wrapblock

function wrapblock(f, io, env, displaycontent)
    println(io, "\\begin{", env, "}[$displaycontent]")
    f()
    println(io, "\\end{", env, "}")
end

import Markdown: wrapinline
function wrapinline(f, io, cmd, options)
    print(io, "\\", cmd, "[$options]{")
    f()
    print(io, "}")
end

function replaceinfile(file, string, replacestring)
    f = open(file, "r+")
    while !eof(f)
        if startswith(f, string; eat=false)
            mark(f)
            buf = IOBuffer()
            startswith(f, string; eat=true) # replace the anchor
            write(buf, f)
            seekstart(buf)
            reset(f)
            latex(f, replacestring)
            write(f, buf)
            close(f)
            return
        end
        read(f, Char)
    end
    @warn "template had no occurence of: $string"
    close(f)
end

function reduceallheaders(content::MD)
    outcontent = MD(config(content))
    for (i, elt) in enumerate(content.content)
        if elt isa Union{Header,LabeledHeader}
            level = elt isa Header ? typeof(elt).parameters[1] : typeof(elt.header).parameters[1]
            if level == 1
                @warn "Cannot reduce a heading of level 1, will skip. Heading name: $(repr(elt.text))"
                push!(outcontent, elt)
            else
                newheader = elt isa Header ? Header(level - 1, elt.text) : LabeledHeader(elt.label, elt.header, level - 1)
                push!(outcontent, newheader)
            end
        else
            push!(outcontent, elt)
        end
    end
    return outcontent
end
function reduceallheaders(content::Nothing)
    return nothing
end

function escape_latex(text::String)
    replacements = (
        '\\' => "\\textbackslash{}",
        '{' => "\\{",
        '}' => "\\}",
        '&' => "\\&",
        '#' => "\\#",
        '^' => "\\textasciicircum{}",
        '_' => "\\_",
        '~' => "\\textasciitilde{}",
        '%' => "\\%",
        '"' => "\\\"",
        '\'' => "\\'"
    )
    return replace(text, replacements...)
end

function escape_label(text::String)
    replacements = (
        ' ' => "_",
        '(' => "",
        ')' => "",
        ',' => "",
    )
    return replace(text, replacements...)
end

# Labels that only rely on the place of origin of the content.
# This design is motivated by reference links, which only provide this information.
function get_location_label(file_title::String, header::String)
    @assert !isempty(file_title) "Cannot make a label for an environment without a known origin file."
    section = isempty(header) ? "statement" : header
    return lowercase(escape_label(file_title * '-' * section))
end

"""
find_file(folder_path::String, file_name::String)

Searches recursively in the folder_path for a file with name file_name.
If the file name is a path, we understand it as a relative path from folder_path.
"""
function find_file(folder_path::String, file_name::String)
    if contains(file_name, '/')
        tentative_path = joinpath(folder_path, file_name)
        if !isfile(tentative_path)
            @error "File $(tentative_path) is not a file"
            return ""
        end
        return tentative_path
    end
    # Search by file name recursively
    file_found = false
    found_file_path = ""
    try
        for (root, dirs, files) in walkdir(folder_path)
            if file_name in files
                if file_found
                    @warn "Multiple files with the name $file_name found in $folder_path"
                else
                    file_found = true
                    found_file_path = joinpath(root, file_name)
                end
            end
        end
    catch e
        @error "Error while searching in folder $folder_path: $e"
    end
    if !file_found
        @warn "File $file_name not found in $folder_path"
    end
    return found_file_path
end
