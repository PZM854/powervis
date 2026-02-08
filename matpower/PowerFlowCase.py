import numpy as np


class PowerFlowCase:
    def __init__(self, bus, branch, gen, success: bool, baseMVA, ext2int=None, int2ext=None, gencost=None):
        self.bus = np.array(bus)
        self.branch = np.array(branch)
        self.gen = np.array(gen)
        self.gencost = np.array(gencost)
        self.success = success
        self.baseMVA = baseMVA

        if ext2int is not None:
            self.ext2int = ext2int
        if int2ext is not None:
            self.int2ext = int2ext

    def copy(self):
        return PowerFlowCase(self.bus.copy(),
                             self.branch.copy(),
                             self.gen.copy(),
                             self.success,
                             self.baseMVA,
                             self.ext2int.copy() if hasattr(self, "ext2int") else None,
                             self.int2ext.copy() if hasattr(self, "int2ext") else None,
                             self.gencost.copy()
                             )

    def __repr__(self):
        return (
            f"PowerFlowCase(bus={self.bus.shape},"
            f"branch={self.branch.shape}"
            f"gen={self.gen.shape}"
            f"success={self.success})"
        )



