# Multi Language [Data Analysis] Project Template

<p float="center">
  <img src="static/r.png" width="150" height="150" hspace="10"/>
  <img src="static/python.png" width="150" height="150" hspace="10"/> 
  <img src="static/julia.png" width="350" height="250" hspace="10"/>
</p>

## About

The purpose of this work is to create a language agnostic project template for data analysis.

## Insipration

I work with Julia, Python, and R.
While the language-specific conventions are different the projects are usually structured similarly.

Usually, I start with what I want to accomplish before I pick what language to work with.
So, I decided that it would helpful to automate and standardize the steps prior to picking a language.

## Operating Systems

Currently focused on Ubuntu-based Linux distros, such as Linux Mint but the setup script should work for most Linux distros.

## Language-Specific Conventions

### Julia

- uses Pgk to manage dependencies
- tests are housed under ./test

### Python

- uses virtual environments or other software such as poetry, virtualenv, etc. to manage dependencies
- tests are housed under ./tests

### R

- uses the renv package manage dependencies
- tests are housed under ./tests

## Similar works

There are many existing works that create language-specific project structures.
Below are some examples.

- Julia:
    - [BestieTemplate](https://github.com/abelsiqueira/BestieTemplate.jl)
    - [DrWatson](https://github.com/JuliaDynamics/DrWatson.jl)
    - [PkgTemplates](https://github.com/JuliaCI/PkgTemplates.jl)
- Python
    - [cookiecutter](https://cookiecutter.readthedocs.io/en/stable/)
    - [GitHub Topics](https://github.com/topics/python-project-template)
- R
    - [usethis](https://usethis.r-lib.org/)
    - [ProjectTemplate](https://github.com/KentonWhite/ProjectTemplate?tab=readme-ov-file)
    - [GitHub User](https://github.com/Pakillo/template)

## How to Use

1. git clone repo
2. Open a terminal and navigate to ^
3. within the terminal run `chmod +x create-project.sh`

### Optional Flags

- programming language flag: `-l`
  - Only affect the testing directory
  - If no language is specified, then both the ./test and ./tests directories are created
  - Takes the following args
    - r
    - py
    - python
    - jl
    - julia
  - **WARNING** only one option should be specified, there is no guardrail if more than one option is passed
- Project directory: `-p`
  - Takes any *existing* path; e.g., `./create-project.sh -p ~/Documents/proj-root`
  - Otherwise the results will be created in the current directory

### Examples

Get the script.

```
mkdir git
cd git
git clone https://github.com/SaintRod/multi-lang-project-template.git
cd multi-lang-project-template
chmod +x create-project.sh
```

A) No clue what language will be used, and the project hasn't been started

```
# the following will create the results in the current directory
# copy the results to the project root directory when it's been created
./create-project.sh
```

B) No clue what language will be used, and the project root directory exists
```
./create-project.sh -p ~/.../project-root
```

C) You know what language will be used, and the project root directory exists
```
# R
./create-project.sh -l r -p ~/.../project-root
./create-project.sh -l R -p ~/.../project-root

# Python
./create-project.sh -l py -p ~/.../project-root
./create-project.sh -l python -p ~/.../project-root
./create-project.sh -l PY -p ~/.../project-root
./create-project.sh -l PYTHON -p ~/.../project-root
./create-project.sh -l pYtHoN -p ~/.../project-root

# Julia
./create-project.sh -l jl -p ~/.../project-root
./create-project.sh -l julia -p ~/.../project-root
./create-project.sh -l JL -p ~/.../project-root
./create-project.sh -l jL -p ~/.../project-root
```

