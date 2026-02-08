import numpy as np
from matpower.PowerFlowCase import PowerFlowCase
from matpower.data_access import get_idx
from scipy.sparse import csr_matrix
from scipy.sparse.linalg import splu


def construct_Bbus(branch, bus):
    """
    Construct Bbus (bus susceptance matrix) for DC power flow.
    Using branch[:, BR_X] and connectivity (F_BUS, T_BUS).

    Returns: sparse CSR matrix (nbus × nbus)
    """

    nbus = bus.shape[0]
    nbranch = branch.shape[0]

    # Indices (you already have these through get_idx)
    F_BUS = get_idx("branch", "F_BUS")
    T_BUS = get_idx("branch", "T_BUS")
    BR_X  = get_idx("branch", "BR_X")

    i = branch[:, F_BUS].astype(int)
    j = branch[:, T_BUS].astype(int)
    x = branch[:, BR_X]

    b = -1 / x  # susceptance (DC model)

    # Build sparse matrix elements
    data = np.concatenate([ b, b, -b, -b ])
    row  = np.concatenate([ i, j, i, j ])
    col  = np.concatenate([ i, j, j, i ])

    Bbus = csr_matrix((data, (row, col)), shape=(nbus, nbus))

    return Bbus

def construct_Bf(branch, bus):
    """
    Construct Bf (branch-flow matrix) mapping angles to branch flows.

    Bf(k, i) = +1/x_k   if branch k starts at i
    Bf(k, j) = -1/x_k   if branch k ends at j
    """

    nbus = bus.shape[0]
    nbranch = branch.shape[0]

    F_BUS = get_idx("branch", "F_BUS")
    T_BUS = get_idx("branch", "T_BUS")
    BR_X  = get_idx("branch", "BR_X")

    f = branch[:, F_BUS].astype(int)
    t = branch[:, T_BUS].astype(int)
    x = branch[:, BR_X]
    b = -1 / x

    data = np.concatenate([ b, -b ])
    row  = np.concatenate([ np.arange(nbranch), np.arange(nbranch) ])
    col  = np.concatenate([ f, t ])

    Bf = csr_matrix((data, (row, col)), shape=(nbranch, nbus))
    return Bf


def make_PTDF(branch, bus):
    """
    Compute PTDF = Bf * inverse(Bbus)
    Slack bus is automatically removed to make Bbus invertible.

    Returns:
      PTDF  (nbranch × nbus)
    """

    nbus = bus.shape[0]

    # Construct matrices
    Bbus = construct_Bbus(branch, bus)
    Bf   = construct_Bf(branch, bus)

    # Remove slack bus (fix angle = 0)
    slack = 0  # you can choose a better slack later
    keep = np.setdiff1d(np.arange(nbus), [slack])

    Bbus_red = Bbus[keep][:, keep]

    # Factorize Bbus_red (LU decomposition)
    lu = splu(Bbus_red.tocsc())

    # Build PTDF
    PTDF = np.zeros((branch.shape[0], nbus))

    for bus_i in keep:
        # Unit injection at bus_i, withdrawal at slack
        rhs = np.zeros(len(keep))
        rhs[np.where(keep == bus_i)[0][0]] = 1

        theta = lu.solve(rhs)  # angles for reduced system

        # assemble full theta (slack = 0)
        full_theta = np.zeros(nbus)
        full_theta[keep] = theta

        # branch flows
        PTDF[:, bus_i] = Bf @ full_theta

    return PTDF


def binarize_PTDF(PTDF: np.ndarray, threshould: float = 0.001):

    return (np.abs(PTDF) > threshould).astype(int)

