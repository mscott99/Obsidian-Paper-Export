
function unrolledmainfile(notesfolder::String, mainfile::String; kwargs...)
    @assert isdir(notesfolder) "Notes folder does not exist"
    @assert isfile(joinpath(notesfolder, mainfile * ".md")) "Main file does not exist"
    f = open(joinpath(notesfolder, mainfile * ".md"))
    md = parse(f, yamlparser; dropfirst=false)
    close(f)

    metadata = md.content[1] isa YAMLHeader ? popfirst!(md.content).content : Dict()

    globalstate = Dict{Symbol,Any}(:environments => Set{Tuple}()) #ids of environments

    merge!(globalstate, kwargs)
    if !haskey(globalstate, :maxdepth)
        globalstate[:maxdepth] = 10
    end
    unrolledcontent = MD(config(md))
    for element in md.content
        if element isa Markdown.Header # do not rename headers in main file
            buffer = IOBuffer()
            Markdown.plaininline(buffer, element.text)
            label = lowercase(String(take!(buffer))) # is meant to be applied after unrolling
            push!(unrolledcontent, LabeledHeader(label, element))
        else
            push!(unrolledcontent, unroll(element, notesfolder, mainfile, globalstate, 0)...)
        end
    end
    return metadata, unrolledcontent
end

function find_heading_content(note::MD, heading::String; removecontent=false)
    inheader = false
    headerlevel = 0
    headercontent = []
    headerindex = 0
    for (i, element) in enumerate(note.content)
        if !inheader && ((element isa Markdown.Header && lowercase(element.text[1]) == lowercase(heading))
                         ||
                         (element isa LabeledHeader && lowercase(element.header.text[1]) == lowercase(heading)))
            inheader = true
            headerindex = i
            headerlevel = typeof(element).parameters[1]
            continue # skip the header 
        end
        if inheader
            if element isa HorizontalRule || (element isa Union{Markdown.Header,LabeledHeader} && typeof(element).parameters[1] <= headerlevel)
                lastindex = i - 1
                if removecontent
                    deleteat!(note.content, headerindex:lastindex)
                end
                break
            end
            push!(headercontent, element)
        end
    end
    return isempty(headercontent) ? nothing : MD(config(note), headercontent...)
end

function unroll(elt::Markdown.Paragraph, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
    outarray = []
    for element in elt.content
        push!(outarray, unroll(element, notesfolder, currentfile, globalstate, depth)...)
    end
    return [Markdown.Paragraph(outarray)]
end

function unroll(elt, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
    return [elt]
end
