mutable struct DisplayLaTeX
    formula::String
end

function latex(io::IO, tex::DisplayLaTeX)
    if match(r"\\begin{", tex.formula) !== nothing
        println(io, tex.formula)
    else
        println(io, "\$\$", tex.formula, "\$\$")
    end
end

function latexinline(io::IO, tex::DisplayLaTeX) # compensate for display is inline
    println(io)
    latex(io, tex)
end

mutable struct InlineLaTeX
    formula::String
end

import Base: lowercase
function lowercase(s::InlineLaTeX)
    return lowercase(s.formula)
end

function latexinline(io::IO, tex::InlineLaTeX)
    print(io, '$', tex.formula, '$')
end

show(io::IO, tex::InlineLaTeX) =
    print(io, '$', tex.formula, '$')

latex(io::IO, tex::InlineLaTeX) =
    print(io, '$', tex.formula, '$')

show(io::IO, tex::DisplayLaTeX) =
    print(io, "\$\$", tex.formula, "\$\$")

latex(io::IO, tex::LaTeX) =
    (match(r"\\begin{align", tex.formula) !== nothing && return println(io, tex.formula)) || println(io, "\$\$", tex.formula, "\$\$")

# Found in its own paragraph
@breaking true ->
    function displaytex(stream::IO, block::MD)
        withstream(stream) do
            startswith(stream, "\$\$", padding=true) || return false
            mathcontent = readuntil(stream, "\$\$"; newlines=true)
            isnothing(mathcontent) && return false
            mathcontent = replace(mathcontent, r"[ |\t]*\n[\n| |\t]*" => x -> "\n") # remove blank lines
            push!(block, DisplayLaTeX(strip(mathcontent)))
            return true
        end
    end

# found inline
@trigger '$' ->
    function inlinetex(stream::IO, md::MD)
        result = parse_inline_wrapper(stream, "\$")
        #if !startswith(stream, "$$", eat=false) && startswith(stream, '$', eat=false)
        # display math

        #    formula = readuntil(stream, "\$")
        #    return isnothing(formula) ? nothing : InlineLaTeX(strip(formula))
        #else
        #    return nothing
        #end
        return result === nothing ? nothing : InlineLaTeX(result)
    end

@trigger '$' ->
    function displayinlinetex(stream::IO, md::MD)
        result = parse_inline_wrapper(stream, "\$\$")
        return result === nothing ? nothing : DisplayLaTeX(result)
        #=
        if startswith(stream, "\$\$")
            formula = readuntil(stream, "\$\$"; newlines=true)
            return isnothing(formula) ? nothing : DisplayLaTeX(strip(formula))
        else
            return nothing
        end
        =#
    end
