import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
from matpower.data_access import *
from matplotlib.patches import FancyArrowPatch
import math
from collections import defaultdict
from igraph import Graph, plot




def colorbrewer(num_color):
    base = np.array([
        [166,206,227],
        [31,120,180],
        [178,223,138],
        [51,160,44],
        [251,154,153],
        [227,26,28],
        [253,191,111],
        [255,127,0],
        [202,178,214],
        [106,61,154],
        [255,255,153],
        [177,89,40]
    ], dtype=float) / 255.0
    idx = np.floor(np.linspace(0, base.shape[0]-1, num_color)).astype(int)
    return base[idx]


def plot_power_grid(bus, branch, savepath="powergrid_layout.png", layout="neato"):
    # Force close all previous figures
    plt.close("all")

    # Convert input to numpy arrays
    bus = np.array(bus, dtype=float)
    branch = np.array(branch, dtype=float)

    # Extract voltage level (BASE_KV column)
    voltages = get_bus_value(bus=bus, field="BASE_KV") # BASE_KV

    # Build graph structure
    G = nx.Graph()
    for i, v in enumerate(voltages):
        G.add_node(i, voltage=float(v))

    for i in range(len(branch)):
        f = get_branch_value(branch=branch, field="F_BUS", row=i)
        t = get_branch_value(branch=branch, field="T_BUS", row=i)
        G.add_edge(f, t)

    # ----------- Correct layout: spring_layout (most stable for network topology) -----------
    pos = nx.spring_layout(
        G,
        k=0.15,        # Controls inter-node spacing; smaller k → more compact layout
        iterations=400,  # More iterations → stronger convergence and structural stability
        seed=40        # Fix random seed for reproducible layout
    )
    # -----------------------------------------------------------------------------

    # ----------- Drawing -----------
    fig, ax = plt.subplots(figsize=(12, 8))

    nx.draw(
        G, pos,
        node_color=voltages,
        cmap="viridis",
        node_size=35,
        linewidths=0.2,
        edge_color="#999999",
        width=0.4,
        alpha=0.85,
        with_labels=False,
        ax=ax
    )

    ax.set_title("Power Grid Topology (spring layout)", fontsize=14)

    # Automatically adjust figure margins
    plt.tight_layout()

    # Save figure
    fig.savefig(savepath, dpi=300, bbox_inches="tight")

    # Display result
    plt.show()

    print(f"Figure saved to: {savepath}")


import matplotlib.pyplot as plt
import networkx as nx
import numpy as np
import math


def plot_zonal_graph(G_offset, partition=None, savepath="zonal_graph.png"):
    plt.close("all")

    # ================================
    # 1. 读取 zone 的 num_node 与 OpVolt
    # ================================
    num_zones = len(partition.islands)

    zone_sizes = []
    zone_voltages = []

    for i in range(num_zones):
        info = partition.transformer_nodes[i]
        nodenum = info["nodenum"]
        opv = info["Opvolt"]

        # --- 节点大小 (log10 scaling) ---
        level = math.ceil(math.log10(nodenum + 1))
        size = (5 + (level - 1) * 7) * 15
        zone_sizes.append(size)

        # --- 节点电压 ---
        zone_voltages.append(opv)

    # ================================
    # 2. 对电压进行 unique + colorbrewer mapping
    # ================================
    unique_volt = sorted(set(zone_voltages))
    palette = colorbrewer(len(unique_volt))

    volt_to_color_idx = {v: i for i, v in enumerate(unique_volt)}

    node_colors = [palette[volt_to_color_idx[v]] for v in zone_voltages]

    # ================================
    # 3. 边统一风格（黑色）
    # ================================
    edge_widths = [1.2] * G_offset.number_of_edges()

    # ================================
    # 4. 使用 neato 布局
    # ================================
    try:
        pos = nx.nx_agraph.graphviz_layout(G_offset, prog="neato")
    except:
        pos = nx.spring_layout(G_offset, k=0.5, iterations=300, seed=10)

    # ================================
    # 5. 绘图
    # ================================
    fig, ax = plt.subplots(figsize=(12, 10))

    nx.draw_networkx_nodes(
        G_offset, pos,
        node_size=zone_sizes,
        node_color=node_colors,
        edgecolors="black",
        linewidths=1.0,
        ax=ax
    )

    nx.draw_networkx_edges(
        G_offset, pos,
        width=0.8,
        edge_color="#666666",
        arrows=True,
        arrowstyle="-|>",
        arrowsize=5,
        min_target_margin=8,
        ax=ax
    )

    ax.set_axis_off()
    plt.tight_layout()
    plt.savefig(savepath, dpi=300, bbox_inches="tight")
    plt.show()

    print("[OK] Saved zonal graph to:", savepath)


def plot_zonal_graph_dot(G_offset, partition, savepath="zonal_graph_dot.png"):
    """
    使用 Graphviz 的 dot (layered layout) 绘制分层布局的 zonal graph
    """

    plt.close("all")

    # ================================
    # 1. Zone 节点大小 & OpVolt 颜色
    # ================================
    num_zones = len(partition.islands)

    zone_sizes = []
    zone_voltages = []

    for i in range(num_zones):
        info = partition.transformer_nodes[i]
        nodenum = info["nodenum"]
        opv = info["Opvolt"]

        # --- 节点大小 (log10 scaling)，与你现有版本保持一致 ---
        level = math.ceil(math.log10(nodenum + 1))
        size = (5 + (level - 1) * 7) * 15
        zone_sizes.append(size)

        # 节点电压（用于配色）
        zone_voltages.append(opv)

    # ================================
    # 2. colorbrewer 调色板
    # ================================
    unique_volt = sorted(set(zone_voltages))
    palette = colorbrewer(len(unique_volt))

    volt_to_color = {v: palette[i] for i, v in enumerate(unique_volt)}
    node_colors = [volt_to_color[v] for v in zone_voltages]

    # ================================
    # 3. 边统一风格（灰色）
    # ================================
    edge_color = "#666666"

    # ================================
    # 4. 使用 Graphviz dot 分层布局
    # ================================
    try:
        pos = nx.nx_agraph.graphviz_layout(G_offset, prog="dot")
    except:
        print("[WARN] graphviz dot failed, fallback to spring")
        pos = nx.spring_layout(G_offset, k=0.5, iterations=300, seed=10)

    # ================================
    # 5. 绘图
    # ================================
    fig, ax = plt.subplots(figsize=(12, 10))

    nx.draw_networkx_nodes(
        G_offset, pos,
        node_size=zone_sizes,
        node_color=node_colors,
        edgecolors="black",
        linewidths=1.0,
        ax=ax
    )

    nx.draw_networkx_edges(
        G_offset, pos,
        width=0.8,
        edge_color=edge_color,
        arrows=True,
        arrowstyle="-|>",
        arrowsize=5,
        min_target_margin=8,
        ax=ax
    )

    ax.set_axis_off()
    plt.tight_layout()
    plt.savefig(savepath, dpi=300, bbox_inches="tight")
    plt.show()

    print("[OK] Saved dot-layout zonal graph to:", savepath)


def plot_zonal_graph_sugiyama(G_offset, partition, savepath="zonal_graph_sugiyama.png"):
    """
    使用 igraph 的 Sugiyama layered layout
    绘制 zonal graph。

    输入：
        G_offset - 你现有的 zone-level DAG（force layout 使用的同一个）
        partition - 含 zones 的 num_nodes & OpVolt 信息
    """

    # ======================
    # 1. NetworkX → igraph
    # ======================
    nodes = list(G_offset.nodes())
    node_index = {zid: i for i, zid in enumerate(nodes)}

    edges = [(node_index[u], node_index[v]) for u, v in G_offset.edges()]

    g = Graph(directed=True)
    g.add_vertices(len(nodes))
    g.add_edges(edges)

    # ======================
    # 2. 节点大小与颜色
    # ======================
    zone_sizes = []
    zone_colors = []

    # 调色板（你现有的）
    unique_volt = sorted(set([info["Opvolt"] for info in partition.transformer_nodes]))
    palette = colorbrewer(len(unique_volt))
    volt_to_color = {v: palette[i] for i, v in enumerate(unique_volt)}

    for zid in nodes:
        info = partition.transformer_nodes[zid]
        nodenum = info["nodenum"]
        opv = info["Opvolt"]

        # --- 节点大小（log10 scaling，与之前一致） ---
        level = math.ceil(math.log10(nodenum + 1))
        size = (5 + (level - 1) * 7) * 1.8  # igraph 的比例更小
        zone_sizes.append(size)

        # --- 节点颜色 ---
        zone_colors.append(tuple(volt_to_color[opv]))

    # igraph 属性
    g.vs["size"] = zone_sizes
    g.vs["color"] = zone_colors
    g.vs["label"] = [str(z) for z in nodes]

    # ======================
    # 3. Sugiyama layout
    # ======================
    layout = g.layout_sugiyama()

    # igraph 的 layout 对象已经是 [(x,y), (x,y), ...]
    coords = [(float(x), float(y)) for x, y in layout]

    # ======================
    # 4. 绘图
    # ======================
    fig, ax = plt.subplots(figsize=(12, 10))

    plot(
        g,
        target=ax,
        layout=coords,  # 一定是 coords（不是 raw，也不是 layout）
        vertex_size=zone_sizes,
        vertex_color=zone_colors,
        edge_width=1.0,
        edge_arrow_size=0.7,
        bbox=(1000, 800),
    )

    plt.axis("off")
    plt.tight_layout()
    plt.savefig(savepath, dpi=300, bbox_inches="tight")
    plt.show()

    print("[OK] Saved sugiyama zonal graph to:", savepath)