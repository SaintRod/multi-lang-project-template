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

# Only if R is selected and the path is not empty
# 1. If not already installed, install renv in the base R env as it's best practice to use project envs
# 2. Initialize the project env in the project path
# 3. Install usethis
# 4. Create an RStudio .Rproj file
 if [[ "$lang" == "r" && -n "$path" ]]; then
   R -e "
   if (!require('renv', quietly = TRUE)){
     install.packages('renv', repos='http://cran.us.r-project.org')}
   
   renv::init(project = '$path')
   renv::install('usethis')
   usethis::create_project(path = '$path', rstudio=TRUE, open=FALSE)
   q(save = 'no')"
 fi

# The end
echo "Project structure created successfully at $path!"
