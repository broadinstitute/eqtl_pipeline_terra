import sys
import pandas as pd
import anndata
import matplotlib.pyplot as plt

if __name__ == '__main__':

    # load counts
    counts = anndata.read_h5ad(sys.argv[1])

    # plot
    fig,ax = plt.subplots(facecolor='w')
    reads_all = counts.X.A.sum(axis=0)
    ax.hist(reads_all, bins=100)
    ax.set_xlabel('# UMIs')
    ax.set_ylabel('# cells')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{sys.argv[2]}.umis_per_cell.png', dpi=300)
