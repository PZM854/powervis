import pandapower.converter as pc
import pandapower as pp
import re
import matlab.engine
import numpy as np
from matpower.PowerFlowCase import PowerFlowCase
from matpower.data_access import get_idx

def to_numpy(mat):
    """Convert matlab.double to numpy array"""
    return np.array(mat)

def runpf_matlab(path=None, case=None):
    """
    Runs MATPOWER AC power flow through MATLAB Engine and returns bus, gen, branch matrices.
    This function is robust to both MATLAB-side and Python-side errors and safely reports failures.

    Parameters
    ----------
    path : str
        Absolute path to a MATPOWER case file (.m or .mat).

    Returns
    -------
    bus : numpy.ndarray or None
        Bus matrix from MATPOWER results. None if power flow fails.
    gen : numpy.ndarray or None
        Generator matrix from MATPOWER results. None if power flow fails.
    branch : numpy.ndarray or None
        Branch matrix from MATPOWER results. None if power flow fails.
    success : bool
        True if power flow converged; False otherwise.
    """

    if (path is None) and (case is None):
        raise RuntimeError("Neither a valid test case nor a viable path forward")

    if path is not None:
        return runpf_matlab_path(path)
    else:
        return runpf_matlab_case(case)

def runpf_matlab_path(path):
    try:
        # Start MATLAB engine
        eng = matlab.engine.start_matlab()

        # Load MATPOWER case file
        ppc = eng.loadcase(path)
        eng.workspace['ppc'] = ppc  # Make PPC available in MATLAB workspace

        # Set MATPOWER options (MATPOWER 6.0 syntax)
        # Disable all command-window output
        eng.eval("opt = mpoption('OUT_ALL', 0, 'VERBOSE', 0);", nargout=0)

        # Run power flow (silent mode)
        eng.eval("[results, success] = runpf(ppc, opt);", nargout=0)

        # Retrieve convergence flag
        success = bool(eng.workspace['success'])
        if not success:
            print("⚠ Power flow did NOT converge.")
            return None, None, None, False

        # Extract matrices from MATPOWER result struct
        eng.eval("bus = results.bus;", nargout=0)
        eng.eval("gen = results.gen;", nargout=0)
        eng.eval("branch = results.branch;", nargout=0)
        eng.eval("baseMVA = results.baseMVA;", nargout=0)
        eng.eval("gencost = results.gencost;", nargout=0)

        # Convert MATLAB arrays to NumPy arrays
        bus = to_numpy(eng.workspace['bus'])
        gen = to_numpy(eng.workspace['gen'])
        branch = to_numpy(eng.workspace['branch'])
        gencost = to_numpy(eng.workspace['gencost'])
        success = bool(eng.workspace['success'])
        baseMVA = eng.workspace['baseMVA']

        bus, branch, gen, ext2int, int2ext = remap_external_to_internal(bus, branch, gen)
        return PowerFlowCase(bus, branch, gen, success, baseMVA, ext2int, int2ext, gencost)

    except matlab.engine.MatlabExecutionError as e:
        print("❌ MATLAB execution error:", str(e))
        return None, None, None, False

    except Exception as e:
        print("❌ Python-side error:", str(e))
        return None, None, None, False


def runpf_matlab_case(case: PowerFlowCase, dcpf=False):
    """
    Run MATPOWER PF/DC-PF using internal-numbering PowerFlowCase.
    For scheme B: disable MATLAB ext2int completely.
    """
    try:
        eng = matlab.engine.start_matlab()

        # ---- 1. Copy Python internal-case ----
        # bus = case.bus.copy()
        # branch = case.branch.copy()
        # gen = case.gen.copy()

        F_BUS = get_idx("branch", "F_BUS")
        T_BUS = get_idx("branch", "T_BUS")
        GEN_BUS = get_idx("gen", "GEN_BUS")
        BUS_I = get_idx("bus", "BUS_I")
        BUS_TYPE = get_idx("bus", "BUS_TYPE")



        # ---- 2. Python internal (0-based) → MATLAB internal (1-based) ----

        bus, branch, gen = internal_to_external(case)
        gencost = case.gencost
        """
        print("DEBUG bus IDs:", np.sort(bus[:, BUS_I]))
        print("DEBUG branch F:", branch[:, F_BUS].min(), branch[:, F_BUS].max())
        print("DEBUG branch T:", branch[:, T_BUS].min(), branch[:, T_BUS].max())
        print("nbus =", bus.shape[0], "maxBusID =", bus[:, BUS_I].max())
        print("DEBUG gen BUS:", gen[:, GEN_BUS].min(), gen[:, GEN_BUS].max())
        """

        # ---- 3. Convert Python → MATLAB struct ----
        print("Num slack bus:", np.sum(bus[:, BUS_TYPE] == 3))
        print("Slack bus IDs:", bus[bus[:, BUS_TYPE] == 3, BUS_I])

        slack_bus_ids = bus[bus[:, BUS_TYPE] == 3, BUS_I]
        print("Slack bus has generator:",
              np.any(np.isin(gen[:, GEN_BUS], slack_bus_ids)))


        eng.workspace["bus"] = matlab.double(bus.tolist())
        eng.workspace["gen"] = matlab.double(gen.tolist())
        eng.workspace["branch"] = matlab.double(branch.tolist())
        eng.workspace["gencost"] = matlab.double(gencost.tolist())
        eng.workspace["baseMVA"] = float(case.baseMVA)

        eng.eval("""
        ppc = struct();
        ppc.version = '2';
        ppc.baseMVA = baseMVA;
        ppc.bus = bus;
        ppc.gen = gen;
        ppc.branch = branch;
        ppc.gencost = gencost;
        """, nargout=0)

        eng.eval("mpopt = mpoption('OUT_ALL',0,'VERBOSE',0);", nargout=0)

        if dcpf:
            eng.eval("mpopt = mpoption(mpopt, 'model', 'DC');", nargout=0)

        # ---------- 4. Run power flow ----------
        if dcpf:
            eng.eval("[results, success] = rundcpf(ppc, mpopt);", nargout=0)
        else:
            eng.eval("[results, success] = runpf(ppc, mpopt);", nargout=0)

        success = bool(eng.workspace["success"])

        # ---- 5. Retrieve MATLAB result ----
        eng.eval("bus2 = results.bus;", nargout=0)
        eng.eval("gen2 = results.gen;", nargout=0)
        eng.eval("branch2 = results.branch;", nargout=0)
        eng.eval("baseMVA2 = results.baseMVA;", nargout=0)
        eng.eval("gencost2 = results.gencost;", nargout=0)


        bus2 = to_numpy(eng.workspace["bus2"])
        gen2 = to_numpy(eng.workspace["gen2"])
        branch2 = to_numpy(eng.workspace["branch2"])
        baseMVA2 = eng.workspace["baseMVA2"]
        gencost2 = eng.workspace["gencost2"]


        # ---- 6. MATLAB internal (1-based) → Python internal (0-based) ----

        bus, branch, gen, ext2int, int2ext = remap_external_to_internal(bus2, branch2, gen2)
        return PowerFlowCase(bus, branch, gen, success, baseMVA2, ext2int=ext2int, int2ext=int2ext, gencost=gencost2)

    except Exception as e:
        print("❌ MATLAB PF failed:", str(e))
        return None



def remap_external_to_internal(bus, branch, gen):
    # External bus IDs
    ext_ids = bus[:, 0].astype(int)

    # Sorting and building mapping: external → internal
    sorted_ext = np.sort(ext_ids)
    ext2int = {ext: i for i, ext in enumerate(sorted_ext)}
    int2ext = {i: ext for i, ext in enumerate(sorted_ext)}

    # ---- Rewrite bus ----
    # Reorder bus rows according to internal indexing (ensures bus[i] corresponds to internal ID i)
    new_bus = np.zeros_like(bus)
    for i, ext in enumerate(sorted_ext):
        idx = np.where(bus[:, 0] == ext)[0][0]
        new_bus[i] = bus[idx]
        new_bus[i, 0] = i

    # ---- Rewrite branch ----
    new_branch = branch.copy()
    for k in range(len(new_branch)):
        f_ext = int(new_branch[k, 0])
        t_ext = int(new_branch[k, 1])
        new_branch[k, 0] = ext2int[f_ext]
        new_branch[k, 1] = ext2int[t_ext]

    # ================================
    #  Rewrite GEN (GEN_BUS)
    # ================================
    new_gen = gen.copy()
    GEN_BUS = 0   # also magic number; replace properly

    for i in range(len(new_gen)):
        old_bus = int(new_gen[i, GEN_BUS])
        new_gen[i, GEN_BUS] = ext2int[old_bus]

    return new_bus, new_branch, new_gen, ext2int, int2ext


def internal_to_external(case: PowerFlowCase):
    """
    Convert an internal-numbering PowerFlowCase (0-based)
    back into external-numbering (MATPOWER original IDs),
    using case.int2ext and ensuring bus/branch/gen all match.

    Returns:
        bus_ext, branch_ext, gen_ext  (numpy arrays)
    """
    if not hasattr(case, "int2ext"):
        raise RuntimeError("Case has no int2ext mapping; cannot externalize.")

    int2ext = case.int2ext

    # Copy arrays
    bus_int = case.bus.copy()
    branch_int = case.branch.copy()
    gen_int = case.gen.copy()

    # Field indices
    BUS_I = get_idx("bus", "BUS_I")
    F_BUS = get_idx("branch", "F_BUS")
    T_BUS = get_idx("branch", "T_BUS")
    GEN_BUS = get_idx("gen", "GEN_BUS")

    # ========== 1. Externalize BUS ==========
    bus_ext = bus_int.copy()
    for i in range(bus_ext.shape[0]):
        bus_ext[i, BUS_I] = int2ext[int(bus_ext[i, BUS_I])]

    # ========== 2. Externalize BRANCH ==========
    branch_ext = branch_int.copy()
    for k in range(branch_ext.shape[0]):
        f_int = int(branch_ext[k, F_BUS])
        t_int = int(branch_ext[k, T_BUS])
        branch_ext[k, F_BUS] = int2ext[f_int]
        branch_ext[k, T_BUS] = int2ext[t_int]

    # ========== 3. Externalize GEN ==========
    gen_ext = gen_int.copy()
    for g in range(gen_ext.shape[0]):
        gb_int = int(gen_ext[g, GEN_BUS])
        gen_ext[g, GEN_BUS] = int2ext[gb_int]

    return bus_ext, branch_ext, gen_ext
