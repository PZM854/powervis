import numpy as np
from matpower.PowerFlowCase import PowerFlowCase
import os
from waterfall.waterfall import waterfall, waterfall_matlab
from caseio.savecase import save_case


def load_case(filename: str):
    data = np.load(filename, allow_pickle=True)

    ext2int = data["ext2int"].item() if data["ext2int"] is not None else None
    int2ext = data["int2ext"].item() if data["int2ext"] is not None else None

    return PowerFlowCase(
        bus=data["bus"],
        branch=data["branch"],
        gen=data["gen"],
        success=bool(data["success"]),
        baseMVA=float(data["baseMVA"]),
        ext2int=ext2int,
        int2ext=int2ext
    )


def load_or_WT(
    casename: str,
    case_path: str,
    P_inj: float = 1,
    WT_folder: str = ".",
    force_recompute: bool = False,
):
    """
    Load a cached Waterfall case if exists, otherwise compute it.

    Parameters
    ----------
    casename : str
        Name of the MATPOWER case (e.g. 'case300')
    case_path : str
        Path to the original MATPOWER case file
    P_inj : float
        Injection power used in waterfall
    WT_folder : str
        Folder to store WT cases
    force_recompute : bool
        If True, ignore cache and recompute

    Returns
    -------
    PowerFlowCase
    """

    filename = os.path.splitext(casename)[0] + "_WT_" + str(int(P_inj))
    fullpath = os.path.join(WT_folder, filename + ".npz")

    # ---------- Case 1: cached ----------
    if (not force_recompute) and os.path.exists(fullpath):
        print(f"[WT] Found cached case: {fullpath}")
        return load_case(os.path.join(WT_folder, filename + ".npz"))

    # ---------- Case 2: compute ----------
    print(f"[WT] No cached case found. Running waterfall for {casename}, P_inj={P_inj}")

    """
        case_WT = waterfall(
        case_name=casename,
        case_path=case_path,
        P_inj=P_inj
    )
    """
    [topnode, case_WT] = waterfall_matlab(casename)

    save_case(case_WT, os.path.join(WT_folder, filename))

    return case_WT
