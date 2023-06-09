using YAML
mutable struct YAMLHeader
    content::Dict{Any,Any}
end

"Positional parser, parses the YAML header."
function yamlparser(stream::IO, block::MD)
    withstream(stream) do
        startswith(stream, "---") || return false
        buffer = IOBuffer()
        while !eof(stream)
            startswith(stream, "---") && break
            write(buffer, readline(stream, keep=true))
        end
        push!(block, YAMLHeader(YAML.load(String(take!(buffer)))))
        return true
    end
end

import Markdown.parse
function parse(stream::Core.IO, initialparser::Core.Function; flavor=obsidian, dropfirst=true)
    isa(flavor, Symbol) && (flavor = flavors[flavor])
    markdown = MD(flavor)
    if dropfirst
        buffer = MD(flavor)
        initialparser(stream, buffer)
    else
        initialparser(stream, markdown)
    end
    while parse(stream, markdown, flavor)
    end
    return markdown
end