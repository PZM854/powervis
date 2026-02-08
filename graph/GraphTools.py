from scipy.sparse.csgraph import shortest_path
from scipy.sparse import csr_matrix
import networkx as nx
import numpy as np


def geodesic_matrix(G: nx.Graph):
    A = nx.to_scipy_sparse_array(G, format="csr")

    D = shortest_path(A, directed=False, unweighted=True)

    return D


def find_TopPilotNode(G: nx.Graph, D: np.ndarray):
    n = G.number_of_nodes()

    Volt = np.array([G.nodes[i]["Voltage"] for i in range(n)])

    highest = np.where(Volt == Volt.max())[0]
    lowest = np.where(Volt == Volt.min())[0]

    remoteness = D.sum(axis=1)


    scores = remoteness[highest]
    idx = np.argmax(scores)
    topnode = int(highest[idx])

    return topnode, remoteness, highest, lowest


def find_BottomPilotNode(D: np.ndarray, topnode: int, lowest_set: np.ndarray):

    dist_from_top = D[:, topnode]

    lowest_dist = dist_from_top[lowest_set]
    idx = np.argmin(lowest_dist)

    bottomnode = int(lowest_set[idx])
    return bottomnode

