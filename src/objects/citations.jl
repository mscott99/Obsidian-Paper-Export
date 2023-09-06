struct Citation
  addresses::Vector{String}
  label::String
end

# Must be added before wikilink to be effective.
# TODO: Add support for labeled citations.
@trigger '[' ->
  function citation(stream::IO, block::MD)
    withstream(stream) do
      skipblank(stream) # for explicit calls
      label = ""
      addresses = []
      if startswith(stream, "[") && !startswith(stream, "@")
        label = readuntil(stream, ']')
      end
      while !((nextAddress = parse_citation_wikilink(stream, block)) |> isnothing)
        push!(addresses, nextAddress)
      end
      if isempty(addresses)
        return nothing
      end
      return Citation(addresses, label)
    end
  end

function latexinline(io::IO, citation::Citation)
  if isempty(citation.label)
    print(io, "\\cite{$(join(citation.addresses, ", "))}")
  else
    print(io, "\\cite[$(citation.label)]{$(join(citation.addresses, ", "))}")
  end
end

function parse_citation_wikilink(stream::IO, block::MD)
  withstream(stream) do
    skipblank(stream) # for explicit calls
    if startswith(stream, "[[@")
      return wikilink_content(stream, block, false).address
    elseif startswith(stream, "[@")
      return readuntil(stream, ']') # not sure about what happens here if no closing bracket
    else
      return nothing
    end
  end
end
