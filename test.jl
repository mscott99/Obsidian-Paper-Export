include("./src/main.jl")

args = ["/Users/matthewscott/Documents/Journal_Uneven_Sampling/config.yaml"]
scriptconfig = YAML.load_file(args[1])
if scriptconfig["ignore_quotes"]
    @info "Ignoring quotes from config"
    eval(quote
        import Markdown: BlockQuote
        function latex(io::IO, md::BlockQuote)
            return ""
        end
    end)
end
scriptconfig = Dict(Symbol(key) => value for (key, value) in scriptconfig)
main(scriptconfig)