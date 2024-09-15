#!/bin/bash

# Directory to store temporary dependency files
temp_dir="temp_dependencies"
output_file="all_dependencies.txt"
package_metadata_file="Packages"  # Path to the Packages metadata file

# File to store the dependencies array
dependencies_output_file="dependencies_output.txt"

# Create or empty the output file
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
        echo "No dependencies found for $package_name" > "$output_file"
    fi
}

# Function to resolve dependencies recursively for primary and secondary levels
resolve_dependencies() {
    local package_name=$1
    local output_file=$2

    # Fetch primary dependencies for the package
    primary_dep_file="${temp_dir}/${package_name}_dep.txt"
    fetch_dependencies "$package_name" "$primary_dep_file"

    # Read and format the primary dependencies
    if grep -q "No dependencies found" "$primary_dep_file"; then
        echo "{$package_name, No dependencies found for $package_name}" >> "$output_file"
    else
        primary_dependencies=$(cat "$primary_dep_file" | tr '\n' ',' | sed 's/,$//')  # Format as comma-separated
        echo "{$package_name, $primary_dependencies}" >> "$output_file"

        # Resolve secondary dependencies for each primary dependency
        while IFS= read -r line; do
            primary_dep_name=$(echo "$line" | awk '{print $1}')  # Get the package name only
            secondary_dep_file="${temp_dir}/${primary_dep_name}_dep.txt"

            # Fetch secondary dependencies for the primary dependency
            if [[ ! -f "$secondary_dep_file" ]]; then
                fetch_dependencies "$primary_dep_name" "$secondary_dep_file"
            fi

            # Format secondary dependencies and append them to the output file
            if grep -q "No dependencies found" "$secondary_dep_file"; then
                echo "{$primary_dep_name, No dependencies found for $package_name}" >> "$output_file"
            else
                secondary_dependencies=$(cat "$secondary_dep_file" | tr '\n' ',' | sed 's/,$//')
                echo "{$primary_dep_name, $secondary_dependencies}" >> "$output_file"
            fi
        done < "$primary_dep_file"
    fi
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
    resolve_dependencies "$package_name" "$output_file"

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
