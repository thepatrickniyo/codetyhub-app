"""
graph_builder.py
----------------
Builds and serialises the CodetyHub STEM curriculum as a NetworkX Directed
Acyclic Graph (DAG). Every node is a specific skill/sub-module; directed edges
enforce prerequisite dependencies.

Usage:
    from ML.knowledge_graph.graph_builder import build_graph, load_graph

    G = build_graph()          # Build fresh from dag_data.json
    G = load_graph()           # Convenience alias

    # Inspect
    print(list(G.nodes(data=True)))
    print(list(G.predecessors("linear_regression")))
"""

import json
import os
from pathlib import Path
import networkx as nx

_DAG_DATA_PATH = Path(__file__).parent / "dag_data.json"


def build_graph(dag_data_path: str | Path = _DAG_DATA_PATH) -> nx.DiGraph:
    """
    Construct a NetworkX DiGraph from the DAG JSON spec.

    Args:
        dag_data_path: Path to the JSON file containing nodes and edges.

    Returns:
        nx.DiGraph with node attributes (label, level) and edges representing
        prerequisites (A → B means A is required before B).

    Raises:
        FileNotFoundError: If dag_data_path does not exist.
        ValueError: If the resulting graph contains a cycle (not a valid DAG).
    """
    dag_data_path = Path(dag_data_path)
    if not dag_data_path.exists():
        raise FileNotFoundError(f"DAG data file not found: {dag_data_path}")

    with open(dag_data_path, "r") as f:
        data = json.load(f)

    G = nx.DiGraph()

    # Add nodes with metadata
    for node in data["nodes"]:
        G.add_node(
            node["id"],
            label=node["label"],
            level=node["level"],
        )

    # Add directed prerequisite edges
    for edge in data["edges"]:
        G.add_edge(edge["from"], edge["to"])

    # Validate DAG (must be acyclic)
    if not nx.is_directed_acyclic_graph(G):
        cycles = list(nx.simple_cycles(G))
        raise ValueError(f"Graph contains cycles — not a valid DAG: {cycles}")

    return G


# Module-level singleton (loaded once)
_graph_cache: nx.DiGraph | None = None


def load_graph() -> nx.DiGraph:
    """
    Return the cached DAG singleton. Builds it on first call.

    Returns:
        nx.DiGraph — the full STEM curriculum knowledge graph.
    """
    global _graph_cache
    if _graph_cache is None:
        _graph_cache = build_graph()
    return _graph_cache


def get_all_skills() -> list[str]:
    """Return a sorted list of all skill node IDs."""
    return sorted(load_graph().nodes())


def get_prerequisites(skill_id: str) -> list[str]:
    """
    Return the direct prerequisites for a given skill.

    Args:
        skill_id: Node ID (e.g. "linear_regression")

    Returns:
        List of direct predecessor node IDs.
    """
    G = load_graph()
    if skill_id not in G:
        raise KeyError(f"Skill '{skill_id}' not found in knowledge graph.")
    return list(G.predecessors(skill_id))


def get_all_prerequisites(skill_id: str) -> list[str]:
    """
    Return ALL ancestors (transitive prerequisites) for a skill.

    Args:
        skill_id: Target skill node ID.

    Returns:
        List of all ancestor node IDs in topological order.
    """
    G = load_graph()
    if skill_id not in G:
        raise KeyError(f"Skill '{skill_id}' not found in knowledge graph.")
    ancestors = nx.ancestors(G, skill_id)
    subgraph = G.subgraph(ancestors)
    return list(nx.topological_sort(subgraph))


def get_unlocked_skills(skill_id: str) -> list[str]:
    """
    Return skills that become directly available after mastering skill_id.

    Args:
        skill_id: Completed skill node ID.

    Returns:
        List of directly succeeding node IDs.
    """
    G = load_graph()
    if skill_id not in G:
        raise KeyError(f"Skill '{skill_id}' not found in knowledge graph.")
    return list(G.successors(skill_id))


def describe_graph() -> dict:
    """
    Return summary statistics about the knowledge graph.

    Returns:
        Dict with node count, edge count, longest path length, root nodes,
        and leaf nodes.
    """
    G = load_graph()
    roots = [n for n in G if G.in_degree(n) == 0]
    leaves = [n for n in G if G.out_degree(n) == 0]
    longest = nx.dag_longest_path_length(G)

    return {
        "total_skills": G.number_of_nodes(),
        "total_edges": G.number_of_edges(),
        "longest_path_length": longest,
        "root_skills": roots,
        "leaf_skills": leaves,
        "is_dag": nx.is_directed_acyclic_graph(G),
    }


if __name__ == "__main__":
    import json

    stats = describe_graph()
    print("Knowledge Graph Summary:")
    print(json.dumps(stats, indent=2))

    print("\nPrerequisites for 'linear_regression':")
    print(get_prerequisites("linear_regression"))

    print("\nAll prerequisites for 'fine_tuning_llms':")
    print(get_all_prerequisites("fine_tuning_llms"))
