#!/bin/bash

# Define directories
dirs=(
    "data"
    "data/input"
    "data/output"
    "docs"
    "config"
    "notebooks"
    "src"
    "scripts"
    "tests"
    "test"
)

# Define files
files=(
    ".gitignore"
    "LICENSE"
    "README.md"
)

# Create directories
echo "Creating directories..."
for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    echo "Created $dir"
done

# Create files
echo "Creating files..."
for file in "${files[@]}"; do
    touch "$file"
    echo "Created $file"
done

echo "Project structure created successfully!"
