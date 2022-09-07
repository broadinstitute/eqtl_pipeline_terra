import argparse
import anndata
import matplotlib.pyplot as plt
import pandas as pd

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(dest="counts", type=str,
                        help="H5AD file of counts")
    parser.add_argument(dest="donormap", type=str,
                        help="cell to donor assignments")
    parser.add_argument(dest="group_name", type=str,
                        help="group/village name")
    args = parser.parse_args()

    # load counts
    counts = anndata.read_h5ad(f'{args.counts}')

    # plot umis per cell
    reads_all = counts.X.sum(axis=1).A.ravel()
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(reads_all, bins=100)
    ax.set_xlabel('# UMIs / cell')
    ax.set_ylabel('# cells')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{args.group_name}.umis_per_cell.png', dpi=300)

    # load cell to donor map
    cell_to_donor = pd.read_table(f'{args.donormap}')
    cell_to_donor.columns = "cell donor".split()

    # filter to cells that exist (cells in the count matrix)
    cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.obs_names)]

    # plot genes per cell
    fig,ax = plt.subplots(facecolor='w')
    ax.hist((counts.X != 0).sum(axis=1).A.ravel(), bins=100)
    ax.set_xlabel('# genes / cell')
    ax.set_ylabel('# cells')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{args.group_name}.genes_per_cell.png', dpi=300)

    # plot cells per donor
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(cell_to_donor['donor'].value_counts().values, bins=30)
    ax.set_xlabel('# cells / donor')
    ax.set_ylabel('# donors')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{args.group_name}.cells_per_donor.png', dpi=300)
