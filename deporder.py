from collections import defaultdict, deque

# Function to read dependencies from the output_dependencies.txt file
def read_dependencies_from_file(file_path):
    dependencies = []
    with open(file_path, 'r') as f:
        for line in f:
            # Clean the line and skip empty or malformed lines
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            # Parse the dependency as a tuple (package, dependency)
            try:
                pkg, dep = line.split(',', 1)
                pkg = pkg.strip().strip('()').replace('"', '')  # Clean up the package name
                dep = dep.strip().strip('()').replace('"', '')  # Clean up the dependency

                # Remove version numbers from the dependency and package
                pkg_clean = pkg.split()[0]
                dep_clean = dep.split()[0]

                # Avoid adding "No" as a dependency and clean up trailing ')', commas, etc.
                if dep_clean != "No":
                    dep_clean = dep_clean.rstrip("),").strip()  # Remove trailing `)` and commas
                    dependencies.append((pkg_clean, dep_clean))
            except ValueError:
                continue  # Skip malformed lines that don't contain both package and dependency

    return dependencies

# Topological sorting function
def topological_sort(dependencies):
    # Graph and in-degree dictionary
    graph = defaultdict(list)
    in_degree = defaultdict(int)

    # Preprocess the dependencies to remove version numbers and handle single-item tuples
    dependencies_cleaned = []
    for entry in dependencies:
        if len(entry) == 2:
            pkg, dep = entry
            pkg_clean = pkg.split()[0]

            # Handle alternative dependencies (split by |)
            alternatives = dep.split('|')
            dep_clean = alternatives[0].split()[0]  # Pick the first available alternative
            dependencies_cleaned.append((pkg_clean, dep_clean))
        elif len(entry) == 1:
            pkg_clean = entry[0].split()[0]
            dependencies_cleaned.append((pkg_clean, None))  # No dependency

    # Build the graph
    for entry in dependencies_cleaned:
        pkg = entry[0]
        dep = entry[1] if entry[1] is not None else None
        if dep:
            graph[dep].append(pkg)
            in_degree[pkg] += 1
            # Ensure the dependency node exists in the in-degree map
            if dep not in in_degree:
                in_degree[dep] = 0
        else:
            if pkg not in in_degree:
                in_degree[pkg] = 0  # No dependencies for this package

    # Find all nodes with zero in-degree to start the sorting
    queue = deque([pkg for pkg in in_degree if in_degree[pkg] == 0])
    sorted_order = []

    while queue:
        package = queue.popleft()
        sorted_order.append(package)

        # Decrease in-degree of dependents
        for dependent in graph[package]:
            in_degree[dependent] -= 1
            if in_degree[dependent] == 0:
                queue.append(dependent)

    # Check for cycles
    if len(sorted_order) == len(in_degree):
        return sorted_order
    else:
        return "Cycle detected in dependencies!"

# Fetch the dependencies from output_dependencies.txt
dependencies = read_dependencies_from_file("dependencies_output.txt")

# Perform topological sort
order = topological_sort(dependencies)
if order:
    print("Topological order of installation:", order)
else:
    print("There is a cycle in the dependencies.")
