import sys
import pandas as pd
import numpy as np
import anndata
import matplotlib.pyplot as plt
from gtfparse import read_gtf

if __name__ == '__main__':

    # load counts
    counts = anndata.read_h5ad(sys.argv[1])
    counts.obs_names_make_unique()

    # load cell to donor map
    cell_to_donor = pd.read_table(sys.argv[2])
    cell_to_donor.columns = "cell donor".split()

    # filter to cells not assigned to donor
    cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.var_names)]

    # filter out donors with less than 300 cells
    thresh = int(sys.argv[3])
    keep_donors = cell_to_donor['donor'].value_counts()[cell_to_donor['donor'].value_counts()>thresh].index
    cell_to_donor = cell_to_donor[cell_to_donor.donor.isin(keep_donors)]

    # downsample high-UMI cells
    reads_all = counts.X.sum(axis=0).A.ravel()
    median_count = np.median(reads_all)
    scale_factor = np.minimum(1, 2 * median_count / counts.X.A.sum(axis=0) ) # per cell scale factor 
    counts = anndata.AnnData(counts.to_df() * scale_factor)

    # plot
    reads_all = counts.X.sum(axis=0)
    # fig,ax = plt.subplots(facecolor='w')
    # ax.hist(reads_all, bins=100)
    # ax.set_xlabel('# UMIs')
    # ax.set_ylabel('# cells')
    # ax.set_title('after downsampling high-UMI cells')
    # fig.patch.set_facecolor('w')
    # plt.savefig(f'{sys.argv[6]}.umis_per_cell.postfilter.png', dpi=300)

    # filter to the gene list
    keep_genes = pd.read_csv(sys.argv[4], sep='\t', header=None) # the genes with top 50% expression
    keep_genes = keep_genes[0].values

    # sum counts to donors
    donor_counts = pd.DataFrame(columns=keep_genes)
    for donor, cells in cell_to_donor.groupby("donor"):
        # group by donor
        donor_counts.loc[donor] = counts[keep_genes, cells.cell].X.sum(axis=1).ravel() 
    
    # Tranpose to a Genes x Donors table
    gene_counts = donor_counts.T
    gene_counts.index.name = 'gene'

    # get gene info
    gene_info = read_gtf(sys.argv[5])
    gene_info = gene_info.query("feature == 'gene'")
    gene_info = gene_info.groupby("gene_name").first().copy()
    gene_info['TSS'] = gene_info.start.where(gene_info.strand == '+', gene_info.end)

    # drop unknown genes
    gene_counts = gene_counts[gene_counts.index.isin(gene_info.index)]

    # add other columns
    gene_counts["chr"] = gene_counts.index.map(gene_info.seqname).astype(str)
    gene_counts["start"] = gene_counts.index.map(gene_info.TSS)
    gene_counts["end"] = gene_counts.index.map(gene_info.TSS) + 1
    gene_counts["strand"] = gene_counts.index.map(gene_info.strand)

    # write out filtered count matrix
    gene_counts = gene_counts.reset_index()["chr start end gene gene strand".split() +
                                            donor_counts.index.tolist()]
    gene_counts.columns = "#chr start end gid pid strand".split() + donor_counts.index.tolist()
    gene_counts.to_csv(f'{sys.argv[6]}.counts.filtered.txt', sep="\t", index=None)
