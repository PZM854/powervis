import numpy as np
import networkx as nx
from matpower.PowerFlowCase import *
from matpower.data_access import *
import matpower.auxiliary_pf as ap




def graph_from_case(case: PowerFlowCase):
    F_BUS = get_idx(table="branch", field_name="F_BUS")
    T_BUS = get_idx(table="branch", field_name="T_BUS")
    BR_R = get_idx(table="branch", field_name="BR_R")
    BR_X = get_idx(table="branch", field_name="BR_X")
    RATE_A = get_idx(table="branch", field_name="RATE_A")
    BASE_KV = get_idx(table="bus", field_name="BASE_KV")

    bus = case.bus
    branch = case.branch

    f = branch[:, F_BUS].astype(int)
    t = branch[:, T_BUS].astype(int)

    Opvolt = (bus[f, BASE_KV] + bus[t, BASE_KV])/2
    IsTrafo = (bus[f, BASE_KV] != bus[t, BASE_KV])
    Cap = branch[:, RATE_A]
    Weight = np.abs(branch[:, BR_X])

    G = nx.MultiGraph()
    for i in range(bus.shape[0]):
        G.add_node(i, Voltage=bus[i, BASE_KV])
    for i in range(branch.shape[0]):
        G.add_edge(
            f[i],
            t[i],
            EdgeIndex=i,
            Cap=Cap[i],
            Weight=Weight[i],
            Opvolt=Opvolt[i],
            IsTrafo=bool(IsTrafo[i])
        )

    return G
