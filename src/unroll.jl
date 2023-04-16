
function unrolledmainfile(notesfolder::String, mainfile::String)
    @assert isdir(notesfolder) "Notes folder does not exist"
    @assert isfile(joinpath(notesfolder, mainfile * ".md")) "Main file does not exist"
    md = nothing
    md = open(joinpath(notesfolder, mainfile * ".md")) do f
        parse(f, yamlparser)
    end
    metadata = md.content[1] isa YAMLHeader ? popfirst!(md.content).content : Dict()
    globalstate = Dict("environments" => Set())
    unrolledcontent = MD(config(md))
    for element in md.content
        if element isa Markdown.Header # do not rename headers in main file
            buffer = IOBuffer()
            Markdown.plaininline(buffer, element.text)
            label = lowercase(String(take!(buffer))) # is meant to be applied after unrolling
            push!(unrolledcontent, LabeledHeader(label, element))
        else
            push!(unrolledcontent, unroll(element, notesfolder, mainfile, globalstate)...)
        end
    end
    return metadata, unrolledcontent
end

function wikilink_label(elt::Wikilink)
    if elt.header |> isempty || elt.header == "Statement"
        return elt.address
    else
        return lowercase(elt.header * ':' * elt.address)
    end
end

function find_heading_content(note::MD, heading::String)
    inheader = false
    headerlevel = 0
    headercontent = []
    for element in note.content
        if !inheader && element isa Markdown.Header && element.text[1] == heading
            inheader = true
            headerlevel = typeof(element).parameters[1]
            continue # skip the header 
        end
        if inheader
            if element isa HorizontalRule || (element isa Markdown.Header && typeof(element).parameters[1] <= headerlevel)
                break
            end
            push!(headercontent, element)
        end
    end
    return MD(config(note), headercontent...)
end

function unroll(elt::Wikilink, notesfolder::String, currentfile::String, globalstate::Dict)
    if elt.embed
        if wikilink_label(elt) in globalstate["environments"]
            elt.embed = false
            return [Paragraph([elt])] # non-embed wikilinks are inline.
        end
        filepath = joinpath(notesfolder, elt.address * ".md")
        local filecontent
        if isfile(filepath)
            filecontent = open(filepath) do f
                parse(f, yamlparser)
            end
        else
            @warn "File $filepath does not exist"
            elt.embed = false
            return [Paragraph([elt])]
        end

        if elt.header != ""
            filecontent = find_heading_content(filecontent, elt.header)
        end
        currentfile = elt.address
        unrolledcontent = []
        if filecontent[1] isa YAMLHeader
            popfirst!(filecontent)
        end
        for element in filecontent.content
            push!(unrolledcontent, unroll(element, notesfolder, currentfile, globalstate)...)
        end
        return unrolledcontent
    else
        return [elt]
    end
end

function unroll(elt::Markdown.Paragraph, notesfolder::String, currentfile::String, globalstate::Dict)
    outarray = []
    for element in elt.content
        push!(outarray, unroll(element, notesfolder, currentfile, globalstate)...)
    end
    return [Markdown.Paragraph(outarray)]
end

function sectionlabel(header::Header)
    buffer = IOBuffer()
    Markdown.plaininline(buffer, header.text)
    return lowercase(String(take!(buffer))) # is meant to be applied after unrolling
end

function sectionlabel(originalheader::Header, address::String)
    return lowercase(address * ':' * sectionlabel(header)) # before unrolling
end


function unroll(elt::Markdown.Header, notesfolder::String, currentfile::String, globalstate::Dict)
    label = currentfile * ':' * Markdown.plaininline(elt.text)
    return [LabeledHeader(label, elt)]
end

function unroll(elt::Environment, notesfolder::String, currentfile::String, globalstate::Dict)
    if elt.content[1] isa Wikilink && elt.content[1].embed
        elt.label = wikilink_label(elt.content[1])
    end
    outarray = []
    for element in elt.content.content
        push!(outarray, unroll(element, notesfolder, currentfile, globalstate)...)
    end
    elt.content.content = outarray
    push!(globalstate["environments"], elt.label)
    return [elt]
end

function unroll(elt, notesfolder::String, currentfile::String, globalstate::Dict)
    return [elt]
end
