mutable struct Environment
    content::MD
    environmentname::String
    originalfile::String
    originalheader::String
    function Environment(content::MD, environmentname::String, originalfile::String="", originalheader::String="")
        return new(content, environmentname, originalfile, originalheader)
    end
end

@breaking true ->
    function environment(stream::IO, block::MD)
        withstream(stream) do
            startswith(stream, "::") && return false # we need a name for an environment
            envbuffer = IOBuffer()
            envbuffer = IOBuffer()
            while true
                eof(stream) && return false
                startswith(stream, ' ') && return false
                startswith(stream, '\n') && return false
                startswith(stream, "::") && break
                write(envbuffer, read(stream, Char))
            end
            environmentname = String(take!(envbuffer))

            skipwhitespace(stream)
            content = MD(config(block))
            env = Environment(content, environmentname)

            #embedded environment
            if startswith(stream, "![[", eat=false)
                wikilinkobj = inline_embedwikilink(stream, content)
                isnothing(wikilinkobj) && return false
                env.originalfile = wikilinkobj.address
                env.originalheader = wikilinkobj.header
                push!(content, wikilinkobj)
                push!(block, env)
                return true
            end

            # env that is a reference to a file
            if startswith(stream, "[[", eat=false)
                wikilinkobj = wikilink(stream, content)
                isnothing(wikilinkobj) && return false
                push!(content, wikilinkobj)
                push!(block, env)
                return true
            end

            #explicit environment
            while !eof(stream)
                skipwhitespace(stream)
                if startswith(stream, "::$environmentname")
                    push!(block, env)
                    return true
                end
                parse(stream, content)
            end
            return false # environment was never closed; do not parse it.
        end
    end

function unroll(elt::Environment, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
    #if elt.content[1] isa Wikilink && elt.content[1].embed
    #    elt.label = wikilink_label(elt.content[1])
    #end
    if !(elt.content[1] isa Wikilink) && length(elt.content) == 1 && elt.originalfile |> isempty
        elt.originalfile = currentfile
    end

    # If file was not already given by the address of a wikilink.
    # if elt.label |> isempty && !isempty(elt.originalfile)
    #     elt.label = lowercase(elt.originalfile)
    #     if elt.environmentname == "proof"
    #         elt.label = "proof:" * elt.label
    #     end
    # end

    # Case where this is a link with an attribute, revert from environment to wikilink with attribute.
    if length(elt.content) == 1 && elt.content[1] isa Wikilink && !elt.content[1].embed
        wikilink = elt.content[1]
        wikilink.attribute = elt.environmentname
        return [Paragraph([wikilink])] # wikilink must be inline.
    end

    # Case of a repeated embed. We change it to a reference.
    if length(elt.content) == 1 && elt.content[1] isa Wikilink && elt.content[1].embed && (elt.content[1].address, elt.content[1].header) in globalstate[:environments]
        @warn "Repeated embed detected for $(elt.content[1].address) $(elt.content[1].header), ignoring environment and reverting it to reference."
        local wikilink = elt.content[1]
        wikilink.embed = false
        return [Paragraph([wikilink])]
    end

    outarray = []
    for element in elt.content.content
        push!(outarray, unroll(element, notesfolder, currentfile, globalstate, depth)...)
    end
    elt.content.content = outarray # content of env is of type MD
    push!(globalstate[:environments], (elt.originalfile, elt.originalheader))
    return [elt]
end

function print_label_command(io::IO, elt::Environment)
    if elt.originalfile |> isempty # Then the env gets no label.
        return
    end
    println(io, "\\label{$(get_location_label(elt.originalfile, elt.originalheader))}")
end

import Markdown: latex
include("../utils.jl")
function latex(io::IO, env::Environment; display_name_of_envs=["definition", "theorem", "proposition", "lemma", "corollary"], kwargs...)
    if env.environmentname == "proof"
        #targetlabel = match(r"(?:[^\:]+):(.*)", env.label)[1]
        @assert !isempty(env.originalfile) "Cannot make a label for an environment without a known origin file."
        wrapblock(io, env.environmentname, "\\hypertarget{$(get_location_label(env.originalfile, env.originalheader))}Proof of \\autoref{$(get_location_label(env.originalfile, "statement"))}") do
            print_label_command(io, env)
            latex(io, env.content)
        end
    elseif env.environmentname in display_name_of_envs
        wrapblock(io, env.environmentname, env.originalfile) do
            print_label_command(io, env)
            latex(io, env.content)
        end
    else
        wrapblock(io, env.environmentname) do
            print_label_command(io, env)
            latex(io, env.content)
        end
    end
    println(io)
end
