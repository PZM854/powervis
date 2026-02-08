import numpy as np
from matpower.data_access import get_idx
from matpower.PowerFlowCase import PowerFlowCase

def run_dcpf(case: PowerFlowCase, slack_bus_internal_id: int = 1):
    """
    Pure Python DCPF, compatible with MATPOWER's internal numbering.

    case.bus[:,BUS_I] is assumed to be 1-based internal numbering.
    This function handles (ID-1) → Python index conversion automatically.
    """

    # indices
    F_BUS = get_idx("branch", "F_BUS")
    T_BUS = get_idx("branch", "T_BUS")
    BR_X  = get_idx("branch", "BR_X")
    PF    = get_idx("branch", "PF")
    PD    = get_idx("bus", "PD")
    VA    = get_idx("bus", "VA")

    bus = case.bus.copy()
    branch = case.branch.copy()
    gen = case.gen.copy()

    nbus = bus.shape[0]
    nbr  = branch.shape[0]

    # -------- Convert internal ID → Python index --------
    # internal ID (1-based) → Python index (0-based)
    bus_index = (bus[:, get_idx("bus","BUS_I")].astype(int) - 1)

    # But we want a mapping: internalID → python index
    # Since internal IDs are already 1..nbus and continuous:
    # internalID k → index = k-1
    # so no remapping needed.

    # Build arrays that map branch endpoints
    f = branch[:, F_BUS].astype(int) - 1
    t = branch[:, T_BUS].astype(int) - 1

    # susceptances
    x = branch[:, BR_X]
    b = -1.0 / x

    # -------- Build Bbus --------
    B = np.zeros((nbus, nbus))

    for k in range(nbr):
        i = f[k]
        j = t[k]
        B[i, i] -= b[k]
        B[j, j] -= b[k]
        B[i, j] += b[k]
        B[j, i] += b[k]

    # -------- Net Injection P --------
    P = -bus[:, PD]

    # Slack bus is given in internal ID (1-based)
    slack = slack_bus_internal_id - 1   # convert to python index

    keep = np.ones(nbus, dtype=bool)
    keep[slack] = False

    Bred = B[keep][:, keep]
    Pred = P[keep]

    # Solve theta
    thetared = np.linalg.solve(Bred, Pred)
    theta = np.zeros(nbus)
    theta[keep] = thetared

    # Write back angles
    bus[:, VA] = theta

    # -------- Branch flows --------
    flows = b * (theta[f] - theta[t])
    branch[:, PF] = flows

    return PowerFlowCase(bus, branch, gen, True, case.baseMVA)
