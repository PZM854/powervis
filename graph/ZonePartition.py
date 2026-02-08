import numpy as np
import networkx as nx
from matpower.PowerFlowCase import PowerFlowCase
from matpower.data_access import get_idx


class ZonePartition:
    """
    Stores results of voltage-homogeneous island detection.
    """
    def __init__(self, islands, transformer_edges, transformer_nodes):
        self.islands = islands  # list of list of node IDs
        self.transformer_edges = transformer_edges  # list of branch indices
        self.transformer_nodes = transformer_nodes  # nodes connected to transformers

    def __repr__(self):
        return (
            f"ZonePartition(islands={len(self.islands)}, "
            f"transformer_edges={len(self.transformer_edges)}, "
            f"transformer_nodes={len(self.transformer_nodes)})"
        )


def zonelabeller(case: PowerFlowCase):

    """
    zonelabeller:
    - removes transformer branches (based on BASE_KV mismatch)
    - identifies voltage-homogeneous islands
    - returns:
        - ZonePartition (nodes + branch indices)
        - original multigraph
        - transformer-removed multigraph
    """


    F_BUS = get_idx("branch", "F_BUS")
    T_BUS = get_idx("branch", "T_BUS")
    BR_R = get_idx("branch", "BR_R")
    BR_X = get_idx("branch", "BR_X")
    PF = get_idx("branch", "PF")

    BUS_I = get_idx("bus", "BUS_I")
    BASE_KV = get_idx("bus", "BASE_KV")

    """
    Full Python migration of MATLAB zonelabeller.m
    Returns:
        partition : ZonePartition
        G_ori : Undirected graph with transformers removed
        DG_nominal : Directed graph (full network)
    """
    bus = case.bus
    branch = case.branch

    # ---------- Step 1: identify transformer branches ----------
    fb = branch[:, F_BUS].astype(int)
    tb = branch[:, T_BUS].astype(int)

    kv_f = bus[fb, BASE_KV]
    kv_t = bus[tb, BASE_KV]

    is_transformer = (kv_f != kv_t)

    transformer_edges = np.where(is_transformer)[0].tolist()

    transformers = []
    for e in transformer_edges:
        transformers.append({
            "edge": int(e),
            "fb": int(fb[e]),
            "tb": int(tb[e])
        })


    # ---------- Step 2: Construct nominal undirected graph (remove transformers) ----------
    G_ori = nx.MultiGraph()
    G_notrans = nx.MultiDiGraph()

    for i in range(bus.shape[0]):
        G_ori.add_node(i, Voltage=bus[i, BASE_KV])
        G_notrans.add_node(i, Voltage=bus[i, BASE_KV])

    for e in range(branch.shape[0]):
        G_ori.add_edge(
            int(fb[e]),
            int(tb[e]),
            EdgeIndex=e,
            power=branch[e, PF],
            r=branch[e, BR_R],
            x=branch[e, BR_X]
        )
        if not is_transformer[e]:
            G_notrans.add_edge(
                int(fb[e]),
                int(tb[e]),
                EdgeIndex=e,
                power=branch[e, PF],
                r=branch[e, BR_R],
                x=branch[e, BR_X]
            )

    # ---------- Step 3: Find islands (connected components) ----------

    islands = []
    G_cc = G_notrans.to_undirected(as_view=True)

    # connected_components 在 MultiDiGraph 上会自动忽略方向，这正是你要的
    for node_set in nx.connected_components(G_cc):
        node_list = sorted(node_set)
        edge_set = set()

        for u in node_list:
            for u0, v, key, data in G_notrans.edges(u, keys=True, data=True):
                # u0 == u，只是 NetworkX 的返回格式
                if v in node_set:
                    edge_set.add(data["EdgeIndex"])

        islands.append({
            "nodes": node_list,
            "edges": sorted(edge_set)
        })

        transformer_nodes = []
        for l in islands:
            transformer_nodes.append({
                "nodenum": len(l['nodes']),
                "Opvolt": bus[int(l['nodes'][0]), BASE_KV]
            })

    # ---------- Step 4: Wrap results ----------

    partition = ZonePartition(
        islands=islands,
        transformer_edges=transformers,
        transformer_nodes=transformer_nodes
    )

    return partition, G_ori, G_notrans






