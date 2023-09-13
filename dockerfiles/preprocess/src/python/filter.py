import argparse
import math

import anndata
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from gtfparse import read_gtf

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--donors', dest='donor_list', type=str,
                        help="donor IDs to keep (default: %(default)s)", default="ALL")
    parser.add_argument('--genes', dest='gene_list', type=str,
                        help="genes to keep (default: %(default)s)", default="ALL")
    parser.add_argument('--thresh-umis', dest='thresh_umis', type=int,
                        help="minimum # UMIs to keep a cell (default: %(default)s)", default=0)
    parser.add_argument('--thresh-cells', dest='thresh_cells', type=int,
                        help="minimum # cells to keep a donor (default: %(default)s)", default=0)
    parser.add_argument('--remove-pct-exp', dest='remove_pct_exp', type=float,
                        help="remove the bottom percent of expressed genes (default: %(default)s)", default=0.0)
    parser.add_argument('--percent-reads', dest='percent_reads', type=int,
                        help="percent of reads to keep", default=100)
    parser.add_argument('--percent-cells', dest='percent_cells', type=int,
                        help="percent of cells to keep", default=100)
    parser.add_argument('--downscale-median-factor', dest='downscale_median_factor', type=float,
                        help="factor times median to downscale high-UMI cells (default: %(default)s)", default=2.0)
    parser.add_argument('--ignore-chr', dest='ignore_chrs', type=str,
                        help="ignore genes on chromosome", action='append')
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
    counts.var_names_make_unique()

    reads_all = counts.X.sum(axis=1).A.ravel()

    if args.downscale_median_factor > 0:
        # downscale high-UMI cells
        median_count = np.median(reads_all)
        scale_factor = np.minimum(1, args.downscale_median_factor * median_count / (reads_all+1))  # per cell scale factor
        scale_factor = np.expand_dims(scale_factor, axis=1)
        counts = anndata.AnnData(counts.to_df() * scale_factor)
    else:
        counts = anndata.AnnData(counts.to_df())

    # remove low-UMI cells
    counts = anndata.AnnData(counts[reads_all > args.thresh_umis, :].to_df())

    # plot UMIs per cell
    reads_all = counts.X.sum(axis=1)
    fig, ax = plt.subplots(facecolor='w')
    ax.hist(reads_all, bins=100)
    ax.set_xlabel('# UMIs per cell')
    ax.set_ylabel('# cells')
    ax.set_title(f'after downscale high-UMI cells above {args.downscale_median_factor:.2f} x median')
    fig.patch.set_facecolor('w')
    plt.savefig(f'{args.output_prefix}.umis_per_cell.postfilter.png', dpi=300)

    # load cell to donor map
    cell_to_donor = pd.read_table(args.donormap)
    cell_to_donor.columns = "cell donor".split()

    # filter out cells not assigned to donor
    cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.obs_names)]

    # filter out donors with not enough cells
    keep_donors = cell_to_donor['donor'].value_counts()[cell_to_donor['donor'].value_counts() > args.thresh_cells].index
    cell_to_donor = cell_to_donor[cell_to_donor.donor.isin(keep_donors)]

    # filter to donor list
    if args.donor_list != 'ALL':
        keep_donors = pd.read_csv(args.donor_list, sep='\t', header=None)[0].values
        cell_to_donor = cell_to_donor[cell_to_donor.donor.isin(keep_donors)]

    # filter to gene list
    if args.gene_list != 'ALL':
        keep_genes = pd.read_csv(args.gene_list, sep='\t', header=None)[0].values
    elif 0 < args.remove_pct_exp < 100:
        fraction_remove = args.remove_pct_exp / 100
        cell_counts = counts[cell_to_donor.cell, :]
        expression_per_gene = cell_counts.X.sum(axis=0).ravel()
        gene_exp_series = pd.Series(data=expression_per_gene, index=cell_counts.var_names)
        # drop genes with expression 0, and then remove remaining percentage
        threshold = gene_exp_series[gene_exp_series > 0].quantile(fraction_remove)
        keep_genes = gene_exp_series[gene_exp_series > threshold].index
    else:
        keep_genes = counts.var_names  # all the genes in the count matrix

    # sum counts to donors
    donor_counts = pd.DataFrame(columns=keep_genes)
    for donor, cells in cell_to_donor.groupby("donor"):
        # subsample cells
        if (args.percent_cells < 100):
            subsampled_cells = cells.cell[np.random.binomial(1, args.percent_cells / 100,
                                                        len(cells.cell)).astype(np.bool)]
        else:
            subsampled_cells = cells.cell

        # group by donor
        donor_counts.loc[donor] = counts[subsampled_cells, keep_genes].X.sum(axis=0).ravel()

        # subsample reads
        if (args.percent_reads < 100):
            donor_counts.loc[donor] = np.random.binomial(donor_counts.loc[donor], args.percent_reads / 100)

    # transpose to a Genes x Donors table
    gene_counts = donor_counts.T
    gene_counts.index.name = 'gene'

    # get gene info
    gene_info = read_gtf(args.gtf, result_type='pandas')
    gene_info = gene_info.query("feature == 'gene'")
    gene_info = gene_info.groupby("gene_name").first().copy()
    gene_info['TSS'] = gene_info.start.where(gene_info.strand == '+', gene_info.end)

    # drop unknown genes
    if not args.ignore_chrs:
        gene_counts = gene_counts[gene_counts.index.isin(gene_info.index)]
    else:
        keep_gene_info = ~gene_info.seqname.isin(args.ignore_chrs)
        gene_counts = gene_counts[gene_counts.index.isin(gene_info[keep_gene_info].index)]

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
