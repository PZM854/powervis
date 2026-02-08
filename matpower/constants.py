# constants.py
# Full MATPOWER constants converted to Python (0-based indexing)

# ============================================================
# BUS MATRIX FIELD INDICES
# (MATPOWER columns 1...17 ⇒ Python indices 0...16)
# ============================================================

bus_fields = {
    "PQ": 0,              # bus type enumeration (not a column)
    "PV": 1,
    "REF": 2,
    "NONE": 3,

    "BUS_I": 0,
    "BUS_TYPE": 1,
    "PD": 2,
    "QD": 3,
    "GS": 4,
    "BS": 5,
    "BUS_AREA": 6,
    "VM": 7,
    "VA": 8,
    "BASE_KV": 9,
    "ZONE": 10,
    "VMAX": 11,
    "VMIN": 12,

    # OPF-added columns
    "LAM_P": 13,
    "LAM_Q": 14,
    "MU_VMAX": 15,
    "MU_VMIN": 16,
}

# ============================================================
# BRANCH MATRIX FIELD INDICES
# (MATPOWER columns 1...21 ⇒ Python indices 0...20)
# ============================================================

branch_fields = {
    "F_BUS": 0,
    "T_BUS": 1,
    "BR_R": 2,
    "BR_X": 3,
    "BR_B": 4,
    "RATE_A": 5,
    "RATE_B": 6,
    "RATE_C": 7,
    "TAP": 8,
    "SHIFT": 9,
    "BR_STATUS": 10,
    "ANGMIN": 11,
    "ANGMAX": 12,
    "PF": 13,
    "QF": 14,
    "PT": 15,
    "QT": 16,
    "MU_SF": 17,
    "MU_ST": 18,
    "MU_ANGMIN": 19,
    "MU_ANGMAX": 20,
}


# ============================================================
# GENERATOR MATRIX FIELD INDICES
# (MATPOWER columns 1...25 ⇒ Python indices 0...24)
# ============================================================

gen_fields = {
    "GEN_BUS": 0,
    "PG": 1,
    "QG": 2,
    "QMAX": 3,
    "QMIN": 4,
    "VG": 5,
    "MBASE": 6,
    "GEN_STATUS": 7,
    "PMAX": 8,
    "PMIN": 9,
    "PC1": 10,
    "PC2": 11,
    "QC1MIN": 12,
    "QC1MAX": 13,
    "QC2MIN": 14,
    "QC2MAX": 15,
    "RAMP_AGC": 16,
    "RAMP_10": 17,
    "RAMP_30": 18,
    "RAMP_Q": 19,
    "APF": 20,
    "MU_PMAX": 21,
    "MU_PMIN": 22,
    "MU_QMAX": 23,
    "MU_QMIN": 24,
}


# ============================================================
# GENCOST MATRIX FIELD INDICES
# (MATPOWER columns 1...7 ⇒ Python indices 0...6)
# ============================================================

gencost_fields = {
    "MODEL": 0,
    "STARTUP": 1,
    "SHUTDOWN": 2,
    "NCOST": 3,
    "COST": 4,

    # additional cost model codes (1 & 2)，MATLAB also defines them
    "PW_LINEAR": 0,
    "POLYNOMIAL": 1,
}

ct_fields = {
    # ----- column labels for changes table -----
    "CT_LABEL": 1,      # change set label
    "CT_PROB": 2,       # probability of this change set
    "CT_TABLE": 3,      # which data table to modify (bus/gen/branch/load/etc.)
    "CT_ROW": 4,        # which row to modify (0 = all rows)
    "CT_COL": 5,        # which column to modify (or a special code)
    "CT_CHGTYPE": 6,    # type of modification: replace, scale, add
    "CT_NEWVAL": 7,     # new value / multiplier / addition amount

    # ----- named values for CT_TABLE -----
    "CT_TBUS": 1,           # bus table
    "CT_TGEN": 2,           # generator table
    "CT_TBRCH": 3,          # branch table
    "CT_TAREABUS": 4,       # area-wide bus table modification
    "CT_TAREAGEN": 5,       # area-wide generator table modification
    "CT_TAREABRCH": 6,      # area-wide branch table modification
    "CT_TLOAD": 7,          # single bus load modification
    "CT_TAREALOAD": 8,      # area-wide load modification (bus or gen)
    "CT_TGENCOST": 9,       # generator cost table
    "CT_TAREAGENCOST": 10,  # area-wide generator cost modification

    # ----- named values for CT_CHGTYPE -----
    "CT_REP": 1,        # replace old value with CT_NEWVAL
    "CT_REL": 2,        # multiply by CT_NEWVAL (relative scaling)
    "CT_ADD": 3,        # add CT_NEWVAL (shift)

    # ----- special codes for CT_COL when CT_TABLE is load-related -----
    "CT_LOAD_ALL_PQ": 1,    # modify all P & Q loads
    "CT_LOAD_FIX_PQ": 2,    # modify fixed loads (P & Q)
    "CT_LOAD_DIS_PQ": 3,    # modify dispatchable loads (P & Q)
    "CT_LOAD_ALL_P": 4,     # modify all P loads only
    "CT_LOAD_FIX_P": 5,     # modify fixed P loads
    "CT_LOAD_DIS_P": 6,     # modify dispatchable P loads

    # ----- special codes for CT_COL when modifying cost tables -----
    "CT_MODCOST_F": -1,     # vertical scaling/shift of cost curve
    "CT_MODCOST_X": -2,     # horizontal scaling/shift of cost curve
}
