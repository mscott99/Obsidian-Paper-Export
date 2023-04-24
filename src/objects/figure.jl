mutable struct Figure
    address::String
    caption::String
end

function unroll(elt::Figure, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
    if !(isfile(joinpath(notesfolder, globalstate[:filefolder], elt.address)))
        @warn "File folder does not exist"
        elt.address = joinpath(globalstate[:filefolder], elt.address)
        return [elt]
    end
    outfilefolder = joinpath(globalstate[:outfolder], globalstate[:filefolder])
    isdir(outfilefolder) || mkdir(outfilefolder)
    cp(joinpath(notesfolder, globalstate[:filefolder], elt.address), joinpath(outfilefolder, elt.address), force=true)
    elt.address = joinpath(globalstate[:filefolder], elt.address)
    return [elt]
end

function latex(io::IO, elt::Figure)
    wrapblock(io, "figure", "h") do
        println(io, "\\centering")
        wrapinline(io, "includegraphics", "width=0.5\\textwidth") do
            print(io, elt.address)
        end
        println(io)
        wrapinline(io, "caption") do
            latexinline(io, elt.caption)
        end
        println(io)
    end
end