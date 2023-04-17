# Obsidian to LaTeX Math Academic Paper Exporter

This project exports an Obsidian note to a LaTeX math academic paper, retaining embeds as proofs and results. The main feature is to embed contents through Obsidian wikilinks from other local files.

## Usage
1. install julia: use juliaup.

2. Run with:
```bash
julia main.jl <input_folder> <longform_file> <output_file>
```

- `input_folder` should contain all the files that should be visible to the program.
- `longform_file` path to the file which is to be exported along with all its embeds.
- òutput_file` path for the latex output.

For example, running from the root folder, you can build the example as follows:
```
julia main.jl ./examples ./examples/main_note.md ./examples/output.tex
```
## Supported Elements
Most markdown elements that you can find in the obsidian are supported. A notable exception is an embed link that is not on a new line. It will throw an error.
### Markdown headers 
h1 headers become Latex sections h2 and onwards become subsections.

### Mathjax Math
Obsidian-style math is recognized. Anything `$inline_math$`and `$$ display_math`. These are rendered by default with the `\begin{equation*}` environment. If an àlign`or àlign*` environment is within dollar signs, it will be rendered using the corresponding environment instead.

### Note Embeds
Transcribes the content of note referred to by an embed link at the location of the link, in a way that matches what is seen in the reading view. The transcription is recursive; an embed in an embed will be embedded. Embeddings of sections of notes will also be embedded.

### Latex Environments
Results, remarks, proofs, lemmas and corollaries can be generated by specifying breadcrumbs-like attributes in front of the link. It takes the form `<environment_name>::![[FILE_NAME]]` on a new line. The embedded content will be inserted inside of a "environment" latex environment, where "environment".

### Internal References
Standard wikilinks will be converted to an `\autoref{}`. It will reference a latex section which was generated from the same note that is referenced by the wikilink. In case there is no embedded content matching it, it will create a dead reference.

### Figures
Figures are created from embed links referencing an image file. They are recognized by their file suffix. A caption can be added by putting it in the display section of the link: `![[image.jpeg|caption text here]]`.

Images will be copied to a folder "Files" in the output latex folder.

## Markdown Note Structure

I suggest to put each relevant result into its own note with a h1 header "Statement" and one h1 header "Proof"; and possibly one #Remark.

To omit information at the end of files, use a line break `---`, and insert the information after. Only dashed line breaks will be considered for this.

## Demo
See the [exported markdown file](examples/main_note.md). It produces barebones latex, which yields:
![output sample](examples/output/example_output/output.pdf)

# Aknowledgement

See also the Obsidian-to-latex repository in python for an alternative implementation with a different focus.