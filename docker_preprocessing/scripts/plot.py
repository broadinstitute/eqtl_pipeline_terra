import sys
import pandas as pd
import anndata
import matplotlib.pyplot as plt
import numpy as np

if __name__ == '__main__':

    # load counts
    counts = anndata.read_h5ad(sys.argv[1])

    # plot umis per cell
    reads_all = counts.X.sum(axis=0).A.ravel()
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(reads_all, bins=100)
    ax.set_xlabel('# UMIs per cell')
    ax.set_ylabel('# cells')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{sys.argv[3]}.umis_per_cell.png', dpi=300)

    # load cell to donor map
    cell_to_donor = pd.read_table(sys.argv[2])
    cell_to_donor.columns = "cell donor".split()

    # filter to cells that exist
    cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.var_names)]

    # plot genes per cell
    fig,ax = plt.subplots(facecolor='w')
    ax.hist((counts.X != 0).sum(axis=0).A.ravel(), bins=100)
    ax.set_xlabel('# genes per cell')
    ax.set_ylabel('# cells')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{sys.argv[3]}.genes_per_cell.png', dpi=300)

    # plot cells per donor
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(cell_to_donor['donor'].value_counts().values, bins=30)
    ax.set_xlabel('# cells per donor')
    ax.set_ylabel('# donors')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{sys.argv[3]}.cells_per_donor.png', dpi=300)

