struct DoubleQuote
    text::String
end

latexinline(io::IO, quoteobj::DoubleQuote) = print(io, "``$(quoteobj.text)\"")

@trigger '"' ->
    function doublequote(stream::IO, block::MD)
        result = parse_inline_wrapper(stream, "\"")
        return isnothing(result) ? nothing : DoubleQuote(result)
    end