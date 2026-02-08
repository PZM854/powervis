from data_access import *

import pandapower.converter as pc
import pandapower as pp
import os
import numpy as np
from matpowercaseframes import CaseFrames
import matlab.engine
from pypower.api import runpf, ppoption, loadcase
import auxiliary_pf as ap
import to_picture as tp

#eng = matlab.engine.start_matlab()

path_base = r"E:\anaconda\pkgs\pglib_cases\matpower-master\data"
casename = "case300.m"
path = "\\".join([path_base, casename])
print(path)
[bus, gen, branch, success] = ap.runpf_matlab(path)

