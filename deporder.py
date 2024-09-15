from collections import defaultdict, deque

def topological_sort(dependencies):
    # Graph and in-degree dictionary
    graph = defaultdict(list)
    in_degree = defaultdict(int)

    # Build the graph
    for entry in dependencies:
        if len(entry) == 2:
            pkg, dep = entry
            graph[dep].append(pkg)
            in_degree[pkg] += 1
            # Ensure the dependency node exists in the in-degree map
            if dep not in in_degree:
                in_degree[dep] = 0
        elif len(entry) == 1:
            pkg = entry[0]
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

    # If sorted_order includes all packages, there are no cycles
    if len(sorted_order) == len(in_degree):
        return sorted_order
    else:
        # Dependency cycle detected
        return None

# Example dependencies
dependencies = [
    ("apache2", "apache2-bin (= 2.4.52-1ubuntu4)"),
    ("apache2", "apache2-data (= 2.4.52-1ubuntu4)"),
    ("apache2", "apache2-utils (= 2.4.52-1ubuntu4)"),
    ("apache2", "lsb-base"),
    ("apache2", "mime-support"),
    ("apache2", "perl:any"),
    ("apache2", "procps"),
    ("apache2-bin", "perl:any"),
    ("apache2-bin", "libapr1 (>= 1.7.0)"),
    ("apache2-bin", "libaprutil1 (>= 1.6.0)"),
    ("apache2-bin", "libaprutil1-dbd-sqlite3"),
    ("apache2-bin", "libaprutil1-ldap"),
    ("apache2-bin", "libbrotli1 (>= 0.6.0)"),
    ("apache2-bin", "libc6 (>= 2.34)"),
    ("apache2-bin", "libcrypt1 (>= 1:4.1.0)"),
    ("apache2-bin", "libcurl4 (>= 7.28.0)"),
    ("apache2-bin", "libjansson4 (>= 2.4)"),
    ("apache2-bin", "libldap-2.5-0 (>= 2.5.4)"),
    ("apache2-bin", "liblua5.3-0"),
    ("apache2-bin", "libnghttp2-14 (>= 1.15.0)"),
    ("apache2-bin", "libpcre3"),
    ("apache2-bin", "libssl3 (>= 3.0.0~~alpha1)"),
    ("apache2-bin", "libxml2 (>= 2.7.4)"),
    ("apache2-bin", "zlib1g (>= 1:1.1.4)"),
    ("apache2-data",),
    ("apache2-utils", "libapr1 (>= 1.4.8-2~)"),
    ("apache2-utils", "libaprutil1 (>= 1.5.0)"),
    ("apache2-utils", "libc6 (>= 2.34)"),
    ("apache2-utils", "libcrypt1 (>= 1:4.1.0)"),
    ("apache2-utils", "libssl3 (>= 3.0.0~~alpha1)"),
    ("lsb-base",),
    ("mime-support", "mailcap"),
    ("mime-support", "media-types"),
    ("perl:any",),
    ("procps", "libc6 (>= 2.34)"),
    ("procps", "libncurses6 (>= 6)"),
    ("procps", "libncursesw6 (>= 6)"),
    ("procps", "libprocps8 (>= 2:3.3.16-1)"),
    ("procps", "libtinfo6 (>= 6)"),
    ("procps", "lsb-base (>= 3.0-10)"),
    ("procps", "init-system-helpers (>= 1.29~)"),
]

order = topological_sort(dependencies)
if order:
    print("Topological order of installation:", order)
else:
    print("There is a cycle in the dependencies.")
