mutable struct Figure
    address::String
    filepath::String
    caption::String
end
Figure(address::String, caption::String) = Figure(address, "", caption)

function unroll(elt::Figure, notesfolder::String, currentfile::String, globalstate::Dict, depth::Int)
    if isfile(joinpath(notesfolder, globalstate[:filefolder], elt.address))
        inputfilepath = joinpath(notesfolder, globalstate[:filefolder], elt.address)
    elseif isfile(joinpath(notesfolder, "../", globalstate[:filefolder], elt.address))
        inputfilepath = joinpath(notesfolder, "../", globalstate[:filefolder], elt.address)
    else
        @warn "File folder does not exist"
        elt.filepath = joinpath(globalstate[:filefolder], elt.address)
        return [elt]
    end
    outfilefolder = joinpath(globalstate[:outfolder], globalstate[:filefolder])
    isdir(outfilefolder) || mkdir(outfilefolder)
    cp(inputfilepath, joinpath(outfilefolder, elt.address), force=true)
    elt.filepath = joinpath(globalstate[:filefolder], elt.address)
    return [elt]
end

function latex(io::IO, elt::Figure)
    wrapblock(io, "figure", "h") do
        println(io, "\\label{$(elt.address)}")
        println(io, "\\centering")
        wrapinline(io, "includegraphics", "width=0.5\\textwidth") do
            print(io, elt.filepath)
        end
        println(io)
        wrapinline(io, "caption") do
            latexinline(io, elt.caption)
        end
        println(io)
    end
end
