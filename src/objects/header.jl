struct InnerLabeledHeader{l}
  label::String
  header::Header{l}
end

InnerLabeledHeader(label::String, header, l) = InnerLabeledHeader(label, Header(header.text, l))

function latex(io::IO, header::InnerLabeledHeader)
  # latex(io, header.header)
  wrapinline(io, "emph") do
    print(io, escape_latex(header.header.text[1]))
  end
  println(io)
  # No support for labels yet.

  # wrapinline(io, "label") do
  #     print(io, header.label)
  # end
end

struct LabeledHeader{l} # Used for the base file.
  label::String
  header::Header{l}
end

LabeledHeader(label::String, header, l::Int) = LabeledHeader(label, Header(header.text, l))

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

# All headers unrolled here are from embedded content, and so should not produce full headers.
function unroll(elt::Markdown.Header, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
  label = currentfile * ':' * Markdown.plaininline(elt.text)
  return [InnerLabeledHeader(label, elt)]
end
