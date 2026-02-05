# Multi Language [Data Analysis] Project Template

<p float="center">
  <img src="static/r.png" width="150" height="150" hspace="10"/>
  <img src="static/python.png" width="150" height="150" hspace="10"/> 
  <img src="static/julia.png" width="350" height="250" hspace="10"/>
</p>

## About

The purpose of this work is to create a language agnostic project template for data analysis.

## Inspiration

I work with Julia, Python, and R.
While the language-specific conventions are different the projects are usually structured similarly.

Usually, I start with what I want to accomplish before I pick what language to work with.
So, I decided that it would helpful to automate and standardize the steps prior to picking a language.

## Operating Systems

- Linux (shell)
- Windows (powershell)

## Language-Specific Conventions

### Julia

- uses Pgk to manage dependencies
- tests are housed under ./test

### Python

- uses virtual environments or other software such as poetry, virtualenv, etc. to manage dependencies
- tests are housed under ./tests

### R

- uses the renv package to manage dependencies
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
3. select the appropriate file based on your OS

	- Linux:
		- choose the `.sh` extension
		- within the terminal run `chmod +x create-project.sh`
	- Windows
		- choose the `.ps1` extension

### Optional Flags

- `-l`: Programming language flag
  - Only affects the testing directory
  - If no language is specified, then both the ./test and ./tests directories are created
    - Simply delete the unused testing directory when a language for the project is chosen
  - Takes the following args (case insensitive)
    - `r`
    - `py`
    - `python`
    - `jl`
    - `julia`
  - **WARNING** only one option should be specified, there is no guardrail if more than one option is passed
- `-p`: Project directory (required)
  - Takes any *existing* path


## Examples

Get the script.

```
mkdir git
cd git
git clone https://github.com/SaintRod/multi-lang-project-template.git
cd multi-lang-project-template
chmod +x create-project.sh #linux only
```

A) No clue what language will be used, and the project hasn't been started

Create the project structure in the current directory

```
create-project.sh -p . #linux
multi-lang-project-template\create-project.ps1 -p . #windows
```

B) No clue what language will be used, and the project root directory exists
```
./create-project.sh -p ~/.../project-root #linux
.\create-project.ps1 -p ~\...\project-root #windows
```

C) You know what language will be used, and the project root directory exists
```
# R
./create-project.sh -l r -p ~/.../project-root
./create-project.sh -l R -p ~/.../project-root

.\create-project.ps1 -l r -p ~\...\project-root
.\create-project.ps1 -l R -p ~\...\project-root


# Python
./create-project.sh -l py     -p ~/.../project-root
./create-project.sh -l python -p ~/.../project-root
./create-project.sh -l PY     -p ~/.../project-root
./create-project.sh -l PYTHON -p ~/.../project-root
./create-project.sh -l pYtHoN -p ~/.../project-root

.\create-project.ps1 -l py     -p ~\...\project-root
.\create-project.ps1 -l python -p ~\...\project-root
.\create-project.ps1 -l PY     -p ~\...\project-root
.\create-project.ps1 -l PYTHON -p ~\...\project-root
.\create-project.ps1 -l pYtHoN -p ~\...\project-root


# Julia
./create-project.sh -l jl    -p ~/.../project-root
./create-project.sh -l julia -p ~/.../project-root
./create-project.sh -l JL    -p ~/.../project-root
./create-project.sh -l jL    -p ~/.../project-root

.\create-project.ps1 -l jl    -p ~\...\project-root
.\create-project.ps1 -l julia -p ~\...\project-root
.\create-project.ps1 -l JL    -p ~\...\project-root
.\create-project.ps1 -l jL    -p ~\...\project-root
```


### Results

```
project-root/
├── config
├── data
│   ├── input
│   └── output
├── docs        # technical documentation
├── LICENSE
├── notebooks   # literate programming medium
├── README.md
├── scripts     # files that import from ./src
├── src         # functions or modules
├── test        # for Julia
└── tests       # for R and Python
```

Additional details:

- docs - Technical documentation created programmatically or manually by users
- notebooks - Any literate programming medium such as Jupyter Labs, Quarto markdown, RMarkdown, or Pluto notebooks
- test and tests - If both testing directories are present, it implies no language was specified

## Contributing

Contributors welcome!

Fork the repo, make changes, and submit a PR :)
