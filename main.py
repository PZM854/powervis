import os
import numpy as np
import matpower.auxiliary_pf as ap
import graph.to_picture as tp
from caseio.loadcase import load_or_WT
from graph.ZonePartition import zonelabeller
from graph.ZonalAggregation import *

path_base = r"E:\anaconda\pkgs\pglib_cases\matpower-master\data"

casename = "case2869pegase.m"
path = "\\".join([path_base, casename])

case_WT = load_or_WT(casename=casename, case_path=path, WT_folder=".\case_WT", force_recompute=False)

partition, G_ori, G_notrans = zonelabeller(case_WT)

G_zone_multi, G_zone_offset = zonal_aggregation(partition=partition, DIG=G_ori)

"""
for u, v, data in G_zone_offset.edges(data=True):
    print(f"{u} -> {v}: {data['power']}")
"""

G_zone_offset.partition = partition

tp.plot_zonal_graph_sugiyama(partition=partition, G_offset=G_zone_offset)
tp.plot_zonal_graph(partition=partition, G_offset=G_zone_offset)


#bus, branch, ext2int, int2ext = ap.remap_external_to_internal(bus, branch)

"""
if pf_case.success:
    tp.plot_power_grid(pf_case.bus, pf_case.branch)
"""



a = 1
