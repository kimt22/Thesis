#!/bin/bash

# Directory to store temporary dependency files
temp_dir="temp_dependencies"
output_file="all_dependencies.txt"
package_metadata_file="Packages"  # Path to the Packages metadata file

# File to store the dependencies array
dependencies_output_file="dependencies_output.txt"

# Create or empty the output files
> "$output_file"
> "$dependencies_output_file"  # Clear the dependencies output file
mkdir -p "$temp_dir"  # Create the temporary directory if it doesn't exist

# Function to fetch dependencies for a given package and store them
fetch_dependencies() {
    local package_name=$1
    local output_file=$2

    # Extract the block of text for the package
    package_info=$(awk -v pkg="$package_name" '/^Package: / {flag=0} /^Package: / && $2 == pkg {flag=1} flag' "$package_metadata_file")

    # Extract only the dependencies from the "Depends:" section
    dependencies=$(echo "$package_info" | awk '/^Depends:/,/^$/' | head -n 1 | sed 's/Depends: //' | tr ',' '\n' | sed 's/^\s*//g' | sed 's/^[ \t]*//')

    # If there are dependencies, write them to the output file
    if [[ -n "$dependencies" ]]; then
        echo "$dependencies" > "$output_file"
    else
        echo "" > "$output_file"  # Output blank instead of "No dependencies found"
    fi
}

# Function to resolve all levels of dependencies iteratively
resolve_all_dependencies() {
    local package_name=$1
    local output_file=$2

    # Track all resolved dependencies in an array to avoid duplicates
    declare -A resolved_packages
    declare -A seen_dependencies

    # Initialize with the main package
    queue=("$package_name")

    # Loop until no more packages to process
    while [[ ${#queue[@]} -gt 0 ]]; do
        current_package="${queue[0]}"
        queue=("${queue[@]:1}")

        # Skip if already resolved
        if [[ -n "${resolved_packages[$current_package]}" ]]; then
            continue
        fi

        # Fetch dependencies for the current package
        dep_file="${temp_dir}/${current_package}_dep.txt"
        fetch_dependencies "$current_package" "$dep_file"

        # Read dependencies and process them
        if [[ ! -s "$dep_file" ]]; then
            echo "{$current_package, }" >> "$output_file"  # Blank for no dependencies
        else
            dependencies=$(cat "$dep_file" | tr '\n' ',' | sed 's/,$//')  # Format as comma-separated
            echo "{$current_package, $dependencies}" >> "$output_file"
            resolved_packages["$current_package"]=1

            # Add new dependencies to the queue if not already seen
            while IFS= read -r dep_line; do
                dep_name=$(echo "$dep_line" | awk '{print $1}' | sed 's/|.*//' | xargs)  # Get the first alternative of the package name only
                if [[ -n "$dep_name" && -z "${seen_dependencies[$dep_name]}" ]]; then
                    queue+=("$dep_name")
                    seen_dependencies["$dep_name"]=1
                fi
            done < "$dep_file"
        fi
    done
}

# Main script execution
main() {
    local package_name="$1"

    # Validate input
    if [[ -z "$package_name" ]]; then
        echo "Usage: $0 <package-name>"
        exit 1
    fi

    # Start resolving dependencies for the given package
    echo "Resolving dependencies for $package_name..."
    resolve_all_dependencies "$package_name" "$output_file"

    # Display the result
    echo "All dependencies have been written to $output_file"
    cat "$output_file"
}

# Example usage: pass the package name as an argument
main "$1"

# Input file containing the dependencies
input_file="all_dependencies.txt"

# Start creating the dependencies array
echo "dependencies = [" > "$dependencies_output_file"  # Redirect output to the file

# Process each line in the input file
while IFS= read -r line
do
    # Remove curly braces and split the line into package name and dependencies
    clean_line=$(echo "$line" | tr -d '{}')

    # Extract the package name and the dependencies
    package=$(echo "$clean_line" | awk -F ',' '{print $1}' | xargs)  # Get package name (first field)
    dependencies=$(echo "$clean_line" | cut -d',' -f2- | xargs)  # Get dependencies part (everything after the first field)

    # Split the dependencies by comma and print each one on a new line
    IFS=',' read -ra deps_array <<< "$dependencies"
    for dep in "${deps_array[@]}"; do
        dep=$(echo "$dep" | xargs)  # Trim any leading/trailing spaces
        echo "(\"$package\", \"$dep\")," >> "$dependencies_output_file"  # Redirect to the file
    done
done < "$input_file"

# End the dependencies array
echo "]" >> "$dependencies_output_file"

# Display the result
cat "$dependencies_output_file"
