# Obsidian to LaTeX Math Academic Paper Exporter

This project exports an Obsidian note to a LaTeX math academic paper, retaining embeds as proofs and results. The main feature is to embed contents through Obsidian wikilinks from other local files.

## Usage

- install julia

then run with:
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
- Markdown headers => Latex sections, subsections
- Mathjax Math (inline and display) => Latex equations `\begin{equation*}`
- Mathjax Math with inline environment => latex inline
- environment::[[FILE_NAME]] => embedded content inside of a "environment" latex environment, where "environment" can be lemma, corollary, definition, remark, theorem, proof.
- [[FIlE_NAME#Statement]] => embeds into a lemma environment by default
- [[FILE_NAME#Proof]] => embeds into a proof environment.
- [[FILE_NAME]] => latex reference to the emebedded content ![[FILE_NAME]] anywhere else in the file.

## Required Note Structure
Notes about results should have one h1 header "Statement" and one h1 header "Proof".
To omit information at the end of files, use a line break `---`.

## Future Features

Support figures

# Structure

- main.jl: The main script to run the program
- obsidian_parser.jl: Contains functions to parse Obsidian notes
- latex_builder.jl: Contains functions to build LaTeX files from parsed notes
- utils.jl: Contains utility functions used in other scripts

# Aknowledgement

Inspiration from Obsidian-to-latex repository in python.