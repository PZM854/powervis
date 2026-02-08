import matlab.engine
import numpy as np

from matpower.PowerFlowCase import PowerFlowCase
from matpower.data_access import get_idx
import graph.GraphTools as GT
from scipy.sparse import csr_matrix

def makePTDF_matlab(case: PowerFlowCase, topnode: int):
    bus = case.bus.copy()
    branch = case.branch.copy()
    bus[:, get_idx("bus", "BUS_I")] = bus[:, get_idx("bus", "BUS_I")] + 1
    branch[:, [get_idx("branch", "F_BUS"), get_idx("branch", "T_BUS")]] = branch[:, [get_idx("branch", "F_BUS"), get_idx("branch", "T_BUS")]] + 1
    topnode = topnode + 1

    eng = matlab.engine.start_matlab()

    bus_mat = matlab.double(bus.tolist())
    branch_mat = matlab.double(branch.tolist())
    gen_mat = matlab.double(case.gen.tolist())

    eng.workspace["bus"] = bus_mat
    eng.workspace["branch"] = branch_mat
    eng.workspace["gen"] = gen_mat
    eng.workspace["baseMVA"] = float(case.baseMVA)
    eng.workspace["topnode"] = int(topnode)

    eng.eval("PTDF = makePTDF(baseMVA, bus, branch, topnode);", nargout=0)

    PTDF_matlab = eng.workspace["PTDF"]
    PTDF = np.array(PTDF_matlab)

    eng.quit()

    return PTDF


