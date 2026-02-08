from matpower.auxiliary_pf import runpf_matlab
from matpower.PowerFlowCase import PowerFlowCase
from graph.PowerFlowGraph import graph_from_case
import matpower.auxiliary_pf as ap
import graph.GraphTools as GT
from matpower.makePTDF_matlab import makePTDF_matlab
from matpower.makePTDF import make_PTDF, binarize_PTDF
from waterfall.greedy_cover import greedy_cover
from matpower.data_access import get_idx
import numpy as np
import matlab.engine


def waterfall(case_name, case_path, P_inj = 1):
    BaseCase = runpf_matlab(case_path)
    if not BaseCase.success:
        raise RuntimeError("Power Flow did not converge")

    G = graph_from_case(BaseCase)

    Distance = GT.geodesic_matrix(G)

    topnode, remoteness, highest, lowest = GT.find_TopPilotNode(G=G, D=Distance)

    bottomnode = GT.find_BottomPilotNode(D=Distance, topnode=topnode, lowest_set=lowest)

    PTDF_case = makePTDF_matlab(BaseCase, topnode)

    Binary_PTDF = binarize_PTDF(PTDF_case)

    selected_buses = greedy_cover(binary_mat=Binary_PTDF)

    FlowTestCase = BaseCase.copy()
    FlowTestCase.bus[:, get_idx("bus", "PD")] = 0
    #FlowTestCase.gen[:, get_idx("gen", "PG")] = 0

    BUS_I = get_idx("bus", "BUS_I")
    BUS_TYPE = get_idx("bus", "BUS_TYPE")
    GEN_BUS = get_idx("gen", "GEN_BUS")
    PG = get_idx("gen", "PG")

    slack_buses = np.where(FlowTestCase.bus[:, BUS_TYPE] == 3)[0]
    slack_bus = slack_buses[0]

    for i in range(FlowTestCase.gen.shape[0]):
        if FlowTestCase.gen[i, GEN_BUS] != FlowTestCase.bus[slack_bus, BUS_I]:
            FlowTestCase.gen[i, PG] = 0

    FlowTestCase.bus[topnode, get_idx("bus", "PD")] = -P_inj * len(selected_buses)
    FlowTestCase.bus[selected_buses, get_idx("bus", "PD")] = P_inj

    case_WT = ap.runpf_matlab_case(case=FlowTestCase, dcpf=True)

    return case_WT


def waterfall_matlab(casename):

    """
    Run MATLAB waterfall() and return:
        TopPilotnode (int)
        case_WT (MATLAB struct as Python dict-like object)
    """
    eng = matlab.engine.start_matlab()

    eng.addpath(r'E:\MATLAB\R2018b\bin\matpower6.0', nargout=0)
    eng.addpath(r'E:\MATLAB\R2018b\bin\重要专项任务\学术进展和与教授的沟通\conference paper 1\正式代码', nargout=0)

    # 调用 MATLAB 函数
    eng.workspace["casename"] = casename

    eng.eval("[TopPilotnode, results] = waterfall(casename);", nargout=0)

    eng.eval("bus2 = results.bus;", nargout=0)
    eng.eval("gen2 = results.gen;", nargout=0)
    eng.eval("branch2 = results.branch;", nargout=0)
    eng.eval("baseMVA2 = results.baseMVA;", nargout=0)
    eng.eval("gencost2 = results.gencost;", nargout=0)
    eng.eval("success = results.success;", nargout=0)

    success = bool(eng.workspace["success"])
    bus = ap.to_numpy(eng.workspace["bus2"])
    gen = ap.to_numpy(eng.workspace["gen2"])
    branch = ap.to_numpy(eng.workspace["branch2"])
    baseMVA = eng.workspace["baseMVA2"]
    gencost = eng.workspace["gencost2"]
    topnode = eng.workspace["TopPilotnode"]

    bus2, branch2, gen2, ext2int, int2ext = ap.remap_external_to_internal(bus, branch, gen)

    return topnode, PowerFlowCase(bus2, branch2, gen2, success, baseMVA, ext2int, int2ext, gencost)


if __name__ == "__main__":

    path_base = r"E:\anaconda\pkgs\pglib_cases\matpower-master\data"
    casename = "case300.m"
    path = "\\".join([path_base, casename])

    case_WT = waterfall(case_name=casename, case_path=path)


