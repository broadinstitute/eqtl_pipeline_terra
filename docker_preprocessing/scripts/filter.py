import pandas as pd
import numpy as np
import anndata
import matplotlib.pyplot as plt
from gtfparse import read_gtf
import argparse
import scipy.sparse as spp

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--donors', dest='donor_list', type=str,
                        help="donor IDs to keep", default="ALL")
    parser.add_argument('--genes', dest='gene_list', type=str,
                        help="genes to keep", default="ALL")
    parser.add_argument('--thresh-umis', dest='thresh_umis', type=int,
                        help="minimum # UMIs to keep a cell", default=0)
    parser.add_argument('--thresh-cells', dest='thresh_cells', type=int,
                        help="minimum # cells to keep a donor", default=0)
    parser.add_argument(dest="counts", type=str,
                        help="H5AD file of counts")
    parser.add_argument(dest="donormap", type=str,
                        help="cell to donor table")
    parser.add_argument(dest="output_prefix", type=str,
                        help="prefix for output files")
    parser.add_argument(dest="gtf", type=str,
                        help="GTF file of gene info")
    args = parser.parse_args()

    # load counts
    counts = anndata.read_h5ad(args.counts)
    counts.obs_names_make_unique()

    # downsample high-UMI cells
    reads_all = counts.X.sum(axis=0).A.ravel()
    median_count = np.median(reads_all)
    scale_factor = np.minimum(1, 2 * median_count / counts.X.sum(axis=0).A.ravel() ) # per cell scale factor 
    counts = anndata.AnnData(counts.to_df() * scale_factor)

    # remove low-UMI cells
    counts = anndata.AnnData(counts[:, reads_all>args.thresh_umis].to_df())

    # plot UMIs per cell
    reads_all = counts.X.sum(axis=0)
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(reads_all, bins=100)
    ax.set_xlabel('# UMIs per cell')
    ax.set_ylabel('# cells')
    ax.set_title('after downsampling high-UMI cells')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{args.output_prefix}.umis_per_cell.postfilter.png', dpi=300)

    # load cell to donor map
    cell_to_donor = pd.read_table(args.donormap)
    cell_to_donor.columns = "cell donor".split()

    # filter out cells not assigned to donor
    cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.var_names)]

    # filter out donors with not enough cells
    keep_donors = cell_to_donor['donor'].value_counts()[cell_to_donor['donor'].value_counts()>args.thresh_cells].index
    cell_to_donor = cell_to_donor[cell_to_donor.donor.isin(keep_donors)]

    # filter to donor list 
    if args.donor_list != 'ALL':
        keep_donors = pd.read_csv(args.donor_list, sep='\t', header=None)[0].values
        cell_to_donor = cell_to_donor[cell_to_donor.donor.isin(keep_donors)]
    
    # filter to gene list
    if args.gene_list != 'ALL':
        keep_genes = pd.read_csv(args.gene_list, sep='\t', header=None)[0].values
    else:
        keep_genes = counts.obs_names # all the genes in the count matrix 

    # sum counts to donors
    donor_counts = pd.DataFrame(columns=keep_genes)
    for donor, cells in cell_to_donor.groupby("donor"):
        # group by donor
        donor_counts.loc[donor] = counts[keep_genes, cells.cell].X.sum(axis=1).ravel() 
    
    # tranpose to a Genes x Donors table
    gene_counts = donor_counts.T
    gene_counts.index.name = 'gene'

    # get gene info
    gene_info = read_gtf(args.gtf)
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
    gene_counts.to_csv(f'{args.output_prefix}.counts.filtered.txt', sep="\t", index=None)
