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

# Adjust directories based on the -l selection for R
# Only if R is selected
if [[ "$lang" == "r" ]]; then
  R -e "
  if (!require('usethis', quietly = TRUE)){
    install.packages('usethis', repos='http://cran.us.r-project.org')}

  usethis::create_project(normalizePath('$path', winslash = '/'),
    rstudio = TRUE,
    open = rlang::is_interactive())
  
  use_git(message = \"Initial commit\")
  
  q(save = 'no')"
  cd $path
  rm -r R # Remove the default R directory created by usethis. Maybe we should keep it?

# Only if R is selected and the path is not empty
elif [[ "$lang" == "r" && -n "$path" ]]; then
  R -e "
  if (!require('usethis', quietly = TRUE)){
    install.packages('usethis', repos='http://cran.us.r-project.org')}

  usethis::create_project(normalizePath('$path', winslash = '/'),
    rstudio = TRUE,
    open = rlang::is_interactive())
  
  use_git(message = \"Initial commit\")
  
  q(save = 'no')"
  cd $path
  rm -r R # Remove the default R directory created by usethis. Maybe we should keep it?
fi

echo "Project structure created successfully at $path!"

