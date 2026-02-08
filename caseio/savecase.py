import numpy as np
from matpower.PowerFlowCase import PowerFlowCase


def save_case(case: PowerFlowCase, filename: str):

    np.savez(
        filename,
        bus=case.bus,
        branch=case.branch,
        gen=case.gen,
        gencost=case.gencost,
        baseMVA=case.baseMVA,
        success=case.success,
        ext2int=case.ext2int if hasattr(case, "ext2int") else None,
        int2ext=case.int2ext if hasattr(case, "int2ext") else None,
    )
    print(f"Case saved to {filename}")
    return 1


def save_WT_case(case: PowerFlowCase, casename: str, P_inj: float):

    filename_WT = casename + "_WT_" + str(int(P_inj)) + '.npz'

    return save_case(case, filename=filename_WT)

