#!/bin/bash

# Default directories
# May be adjusted based on the -l option
dirs=(
    "data"
    "data/input"
    "data/output"
    "docs"
    "config"
    "notebooks"
    "src"
    "scripts"
)

# Define files
files=(
    ".gitignore"
    "LICENSE"
    "README.md"
)

# Handle optional flags
# -l flag for language-specific directories
# -p path
lang=""
path="."

# Function to convert string to lowercase
to_lowercase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

while getopts ":l:p:" opt; do
  case $opt in
  l)
    lang=$(to_lowercase "$OPTARG")
    ;;
  p)
    path="$OPTARG"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
done

# Check if the specified path exists
if [[ ! -d "$path" ]]; then
  echo "Error: The specified path '$path' does not exist." >&2
  exit 1
fi

# Adjust the directories based on the -l flag
if [[ "$lang" == "r" || "$lang" == "py" || "$lang" == "python" ]]; then
    dirs+=("tests")
elif [[ "$lang" == "jl" || "$lang" == "julia" ]]; then
    dirs+=("test")
else
    dirs+=("test" "tests")
fi

# Create directories
echo "Creating directories at $path..."
for dir in "${dirs[@]}"; do
    mkdir -p "$path/$dir"
    echo "Created $path/$dir"
done

# Create files
echo "Creating files at $path..."
for file in "${files[@]}"; do
    touch "$path/$file"
    echo "Created $path/$file"
done

# Create a .Rproj text file with defaults if R is selected
Rproj="Version: 1.0

RestoreWorkspace: No
SaveWorkspace: No
AlwaysSaveHistory: Default

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 4
Encoding: UTF-8

RnwWeave: knitr
LaTeX: XeLaTeX

AutoAppendNewline: Yes
StripTrailingWhitespace: Yes
LineEndingConversion: Posix"

# Name the .Rproj file based on the directory name
if [ "$lang" == "r" ]; then
dir_name=$(basename "$PWD") # Get the name of the current directory name when path = "." for the .Rproj file. Necessary when creating text .Rproj file. Not necessary if we using usethis::create_project()
  echo "$Rproj" > $path/$dir_name.Rproj
elif [[ "$lang" == "r" && -n "$path" ]]; then
  echo "$Rproj" > $path/$path.Rproj
fi

# Adjust directories based on the -l selection for R
# Only if R is selected
 if [[ "$lang" == "r" ]]; then
   R -e "
   if (!require('renv', quietly = TRUE)){
     install.packages('renv', repos='http://cran.us.r-project.org')}
   
   renv::init(project = '$path')
   q(save = 'no')"

# # Only if R is selected and the path is not empty
 elif [[ "$lang" == "r" && -n "$path" ]]; then
   R -e "
   if (!require('renv', quietly = TRUE)){
     install.packages('renv', repos='http://cran.us.r-project.org')}
   
   renv::init(project = '$path')
   q(save = 'no')"
 fi


echo "Project structure created successfully at $path!"