struct LabeledHeader{l}
    label::String
    header::Header{l}
end

function latex(io::IO, header::LabeledHeader)
    latex(io, header.header)
    wrapinline(io, "label") do
        print(io, header.label)
    end
    println(io)
end

function sectionlabel(header::Header)
    buffer = IOBuffer()
    Markdown.plaininline(buffer, header.text)
    return lowercase(String(take!(buffer))) # is meant to be applied after unrolling
end

function sectionlabel(originalheader::Header, address::String)
    return lowercase(address * ':' * sectionlabel(header)) # before unrolling
end


function unroll(elt::Markdown.Header, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
    label = currentfile * ':' * Markdown.plaininline(elt.text)
    return [LabeledHeader(label, elt)]
end
