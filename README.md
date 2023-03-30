# Obsidian to LaTeX Math Academic Paper Exporter

This project exports an Obsidian note to a LaTeX math academic paper, retaining embeds as proofs and results. The main feature is to embed contents through Obsidian wikilinks from other local files.

## Features

- Parse Obsidian Markdown files
- Convert Obsidian notes into LaTeX files
- Retain embedded content through Obsidian wikilinks
- Support for mathematical expressions, theorems, lemmas, and proofs

## Prerequisites

- Julia (tested on v1.6)

## Usage

1. Clone the repository
2. Place your Obsidian notes in the `examples` folder or any other folder
3. Run the script, specifying the input folder, the main note file, and the output file:

```bash
julia main.jl <input_folder> <longform_file> <output_file>
```

For example:
```
julia main.jl ./examples ./examples/main_note.md ./examples/output.tex
```
This will convert the main_note.md file in the examples folder to a LaTeX file named output.tex.

# Structure

- main.jl: The main script to run the program
- obsidian_parser.jl: Contains functions to parse Obsidian notes
- latex_builder.jl: Contains functions to build LaTeX files from parsed notes
- utils.jl: Contains utility functions used in other scripts