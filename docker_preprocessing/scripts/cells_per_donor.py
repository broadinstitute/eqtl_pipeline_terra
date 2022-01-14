import sys
import pandas as pd
import anndata
import matplotlib.pyplot as plt

if __name__ == '__main__':

    # load counts
    counts = anndata.read_h5ad(sys.argv[1])

    # load cell to donor map
    cell_to_donor = pd.read_table(sys.argv[2])
    cell_to_donor.columns = "cell donor".split()

    # filter to cells that exist
    cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.var_names)]

    # plot
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(cell_to_donor['donor'].value_counts().values, bins=30)
    ax.set_xlabel('# cells')
    ax.set_ylabel('# donors')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{sys.argv[3]}.cells_per_donor.png', dpi=300)
