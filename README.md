# Multi Language [Data Analysis] Project Template

## About

The purpose of this work is to create a language agnostic project template for data analysis.

## Insipration

I work with Julia, Python, and R.
While the language-specific conventions are different the projects are usually similarly structured.

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

Step 1:

1. git clone repo
2. within a terminal: `chmod +x create-project.sh`

Step 2:
1. create an empty directory and name it as desired
2. open a terminal and navigate to ^
3. run the script: `~/multi-lang-project-template/create-project.sh`

Alternatively, you can execute the script (`./create-project.sh`) within the cloned GitHub repo `./multi-lang-project-template` and then copy the results to your project directory.

## Work in Progress

As can be seen above, the current process is a bit manual.
It would be nice to tell the script where to create the results, via an argument perhaps.
For example, `./create-project.sh Documents/path-to-project`

There are two test directories because Julia (./test) differs from Python and R (./tests).
Maybe it's unnecessary to have both ./test and ./tests.
However, for multi-language projects having both would be helpful.
Another argument or option might be helpful to specify which test directory to create: ./test, ./tests, or both

