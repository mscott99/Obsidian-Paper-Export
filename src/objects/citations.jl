struct Citation
  addresses::Vector{String}
end

# Must be added before wikilink to be effective.
@trigger '[' ->
  function citation(stream::IO, block::MD)
    withstream(stream) do
      skipblank(stream) # for explicit calls
      if startswith(stream, "[[@")
        addresses = [wikilink_content(stream, block, false).address]
      elseif startswith(stream, "[@")
        addresses = [readuntil(stream, ']')]
      else
        return nothing
      end
      while !((nextCitations = citation(stream, block)) |> isnothing)
        push!(addresses, nextCitations.addresses...)
      end
      return Citation(addresses)
    end
  end

latexinline(io::IO, citation::Citation) = print(io, "\\cite{$(join(citation.addresses, ", "))}")
