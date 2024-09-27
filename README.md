# template-project

This repository contains the [research compendium](https://research-compendium.science) for the project: X. The compendium is a collection of all digital parts of the research project to date.

## Contents:

### [`code/`](code/)
The [`code/`](code/) directory contains two subdirectories:

[`notebooks/`](code/notebooks/) contains R Markdown or Quarto files that are used for exploratory analysis. They produce figures and documents.  All `.Rmd` and `.qmd` files in [`notebooks/`](code/notebooks/) are knitted to GitHub Flavored Markdown documents to make the GitHub repo browsable.

[`scripts/`](code/scripts/) contains action scripts, i.e. all the code for cleaning, combining, and analysing the data. All paths in the scripts are relative to the root directory (where the `.Rproj` file lives). Each `.R` script has a summary at the top of what it does. The scripts are numbered in the order in which they would typically be run.

### `data/`
The original data is stored in the `data/raw/` subdirectory. Any data that is produced using code is stored in `data/derived/`. Data will be archived separately.

### [`output/`](output/)
The [`output/`](output/) directory contains the subdirectories [`figures/`](output/figures/) and [`results/`](output/results/), which contain the figures used in the paper and other output from analyses, respectively.

### [`docs/`](docs/)
The [`docs/`](docs/) directory contains the [data dictionary](docs/data-dictionary.md) (i.e. metadata), [project notebook](docs/project-notebook.md), [protocols](docs/protocols.md) and any other relevant documents.

## Usage
To reproduce results and figures run the `.R` scripts in [`code/scripts/`](code/scripts/) in the order in which they are labelled.
