# if isdir("/Users/matthewscott/Prog/Obsidian-Paper-Export/examples/output/")
#   rm("/Users/matthewscott/Prog/Obsidian-Paper-Export/examples/output/", recursive=true)
#   @info "deleted output folder for testing"
# end

include("main.jl")
scriptconfig = YAML.load_file("/Users/matthewscott/Documents/Generative_Workshop/config.yaml")
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
checkConfigIsValid(scriptconfig)
generate_latex(scriptconfig[:input_folder_path], scriptconfig[:longform_file_name], scriptconfig[:output_folder_path]; scriptconfig...)
