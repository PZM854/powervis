import numpy as np


def greedy_cover(binary_mat: np.ndarray):

    mat = binary_mat.copy()
    n_rows, n_cols = mat.shape

    select_cols = []
    coverage = mat.sum(axis=0)

    while coverage.max() > 0:
        best_col = int(np.argmax(coverage))
        select_cols.append(best_col)

        covered_rows = np.where(mat[:, best_col] == 1)[0]

        mat[covered_rows, :] = 0

        coverage = mat.sum(axis=0)

    return select_cols

