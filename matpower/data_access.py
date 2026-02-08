# ============================================================
# data_access.py
# Unified access API for MATPOWER-style matrices
# ============================================================

import numpy as np
from matpower.constants import (
    bus_fields,
    branch_fields,
    gen_fields,
    gencost_fields,
    ct_fields,
)

# ============================================================
# INTERNAL ROUTINE
# ============================================================

def _get_value(matrix: np.ndarray, fields: dict, field_name: str, row: int = None):
    """
    Internal universal accessor.

    Parameters
    ----------
    matrix : np.ndarray
        The data matrix (bus / branch / gen / gencost).
    fields : dict
        The dictionary mapping field names → column index.
    field_name : str
        Key in fields dict.
    row : int or None
        If None → return full column
        If int → return matrix[row, column]

    Returns
    -------
    scalar or ndarray
    """

    # 1. 检查字段是否存在
    if field_name not in fields:
        raise KeyError(f"Field '{field_name}' not found in table fields")

    col = fields[field_name]

    # 2. 整列访问
    if row is None:
        return matrix[:, col]

    # 3. 行访问 + 边界检查
    if not (0 <= row < matrix.shape[0]):
        raise IndexError(f"Row index {row} out of bounds")

    return matrix[row, col]


# ============================================================
# PUBLIC API
# Each matrix type has its own small wrapper
# ============================================================

def get_bus_value(bus: np.ndarray, field: str, row: int = None):
    """Access bus matrix"""
    return _get_value(bus, bus_fields, field, row)


def get_branch_value(branch: np.ndarray, field: str, row: int = None):
    """Access branch matrix"""
    return _get_value(branch, branch_fields, field, row)


def get_gen_value(gen: np.ndarray, field: str, row: int = None):
    """Access generator matrix"""
    return _get_value(gen, gen_fields, field, row)


def get_cost_value(cost: np.ndarray, field: str, row: int = None):
    """Access gencost matrix"""
    return _get_value(cost, gencost_fields, field, row)


def get_ct_value(ct: np.ndarray, field: str, row: int = None):
    """Access change-table matrix"""
    return _get_value(ct, ct_fields, field, row)


# ============================================================
# Index accessor API
# ============================================================

def get_idx(table: str, field_name: str):
    def find_table(table):

        table = table.lower()
        if table == "bus":
            return bus_fields
        elif table == "branch":
            return branch_fields
        elif table == "gen":
            return gen_fields
        elif table == "gencost":
            return gencost_fields
        elif table == "ct":
            return ct_fields
        else:
            raise KeyError(f"Field '{table}' not found in table fields")

    field_data = find_table(table)

    if field_name not in field_data:
        raise KeyError(f"key '{field_name}' not found in this field")
    return field_data[field_name]


def get_bus_idx(field_name: str):
    return get_idx(table="bus", field_name=field_name)


def get_branch_idx(field_name: str):
    return get_idx(table="branch", field_name=field_name)


def get_gen_idx(field_name: str):
    return get_idx(table="gen", field_name=field_name)


def get_gencost_idx(field_name: str):
    return get_idx(table="gencost", field_name=field_name)


def get_ct_idx(field_name: str):
    return get_idx(table="ct", field_name=field_name)