import numpy as np
import networkx as nx
from matpower.PowerFlowCase import PowerFlowCase
from matpower.data_access import get_idx
from graph.ZonePartition import ZonePartition
from collections import defaultdict


def build_bus_to_zone(partition: ZonePartition):

    bus_to_zone = {}
    for zid, island in enumerate(partition.islands):
        for bus in island['nodes']:
            bus_to_zone[bus] = zid

    return bus_to_zone


def multi_zonal_graph(partition: ZonePartition, DIG):
    bus_to_zone = build_bus_to_zone(partition)

    G_zonal_multi = nx.MultiDiGraph()

    num_zones = len(partition.islands)

    for zid, island in enumerate(partition.islands):
        G_zonal_multi.add_node(
            zid,
            num_nodes=len(island["nodes"])
        )

    for eidx in partition.transformer_edges:

        for u, v, key, data in DIG.edges(keys=True, data=True):
            if data.get("EdgeIndex") == eidx['edge']:
                zu = bus_to_zone[u]
                zv = bus_to_zone[v]

                if zu != zv:
                    G_zonal_multi.add_edge(
                        zu,
                        zv,
                        EdgeIndex=eidx['edge'],
                        power=data.get("power", 0.0),
                        r=data.get("r", None),
                        x=data.get("x", None),
                        from_bus=u,
                        to_bus=v
                    )
                break

    return G_zonal_multi


def edge_combination(G_multi: nx.MultiDiGraph):

    """
    Combine parallel edges with same (u, v) by summing 'power'.
    MATLAB equivalent: edge_combination
    """

    G_combined = nx.DiGraph()

    # 继承节点与节点属性
    G_combined.add_nodes_from(G_multi.nodes(data=True))

    # (u, v) -> sum(power)
    acc = defaultdict(float)

    for u, v, data in G_multi.edges(data=True):
        p = data.get("power", 0.0)
        acc[(u, v)] += p

    # 建立合并后的边
    for (u, v), p in acc.items():
        G_combined.add_edge(u, v, power=p)

    return G_combined


def edge_offset(G_combined: nx.DiGraph) -> nx.DiGraph:
    """
    Offset reverse-direction edges.
    MATLAB equivalent: edge_offset
    """
    G_offset = nx.DiGraph()
    G_offset.add_nodes_from(G_combined.nodes(data=True))

    # 复制边数据，便于删除
    edges = []
    for u, v, data in G_combined.edges(data=True):
        edges.append([u, v, data.get("power", 0.0)])

    i = 0
    while i < len(edges):
        u, v, p = edges[i]

        # 查找反向边
        idx_rev = None
        for j in range(len(edges)):
            if edges[j][0] == v and edges[j][1] == u:
                idx_rev = j
                break

        if idx_rev is not None:
            p_rev = edges[idx_rev][2]
            edges[i][2] = p - p_rev
            edges.pop(idx_rev)

            if idx_rev < i:
                i -= 1
        i += 1

    # 统一方向（功率为正）
    for u, v, p in edges:
        if p > 0:
            G_offset.add_edge(u, v, power=p)
        elif p < 0:
            G_offset.add_edge(v, u, power=-p)

    return G_offset


def offset_zonal_graph(G_zone_multi):
    """
    From zone-level MultiDiGraph:
    1) combine parallel edges
    2) offset reverse directions
    """
    G_combined = edge_combination(G_zone_multi)
    G_offset = edge_offset(G_combined)
    return G_offset



def zonal_aggregation(
    partition,
    DIG
):
    """
    Build:
    1) multi-zonal graph (zone-level multigraph, transformer-resolved)
    2) zonal offset graph (aggregated, net-flow DAG)

    Returns
    -------
    G_zone_multi : nx.MultiDiGraph
    G_zone_offset : nx.DiGraph
    """
    G_zonal_multi = multi_zonal_graph(partition=partition, DIG=DIG)
    G_zonal_offset = offset_zonal_graph(G_zonal_multi)

    return G_zonal_multi, G_zonal_offset

