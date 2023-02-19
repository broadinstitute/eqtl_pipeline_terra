import argparse
import anndata
import pandas as pd
import numpy as np
from gtfparse import read_gtf

parser = argparse.ArgumentParser()
parser.add_argument('--percent-reads', dest='percent_reads', type=int,
                    help="percent of reads to keep", default=100)
parser.add_argument('--donors', dest='donor_list', type=str,
                    help="donor IDs to keep, comma separated", default="ALL")
parser.add_argument('--genes', dest='gene_list', type=str,
                    help="genes to keep, comma separated", default="ALL")
parser.add_argument('--percent-cells', dest='percent_cells', type=int,
                    help="percent of cells to keep", default=100)
parser.add_argument(dest="counts", type=str,
                    help="H5AD file of counts")
parser.add_argument(dest="donormap", type=str,
                    help="cell to donor table")
parser.add_argument(dest="gtf", type=str,
                    help="gtf file to reference genes")
parser.add_argument(dest="output", type=str,
                    help="file to write output table to")

args = parser.parse_args()

# get gene info
# mnt/DATA/reference/Homo_sapiens.GRCh38.93.gtf.gz
gene_info = read_gtf(args.gtf)
gene_info = gene_info.query("feature == 'gene'")
gene_info = gene_info.groupby("gene_name").first().copy()
gene_info['TSS'] = gene_info.start.where(gene_info.strand == '+', gene_info.end)

# load counts
counts = anndata.read_h5ad(args.counts, backed=False)

# load cell to donor map
cell_to_donor = pd.read_table(args.donormap)
cell_to_donor.columns = "cell donor".split()

# filter to cells that exist
prefilter = len(cell_to_donor)
cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.var_names)]
postfilter = len(cell_to_donor)
if prefilter != postfilter:
    print(f"Donor map reduced from {prefilter} to {postfilter} cells based on count data labels")

# filter to cells of donors we want to keep
if args.donor_list != 'ALL':
    donors = set(args.donor_list.split(","))
    cell_to_donor = cell_to_donor[cell_to_donor.donor.isin(donors)]
    counts = counts[:, cell_to_donor.cell]

# filter counts to genes we want to keep
if args.gene_list != 'ALL':
    keep_genes = args.gene_list.split(",")
else:
    keep_genes = counts.obs_names # all the genes in the count matrix 
    # keep_genes = slice()  # when used as an index, equivalent to ':'

# sum counts to donors
donor_counts = pd.DataFrame(columns=keep_genes)
for donor, cells in cell_to_donor.groupby("donor"):
    # subsample cells
    if (args.percent_cells < 100):
        subsampled_cells = cells.cell[np.random.binomial(1, args.percent_cells / 100,
                                                     len(cells.cell)).astype(np.bool)]
    else: 
        subsampled_cells = cells
    donor_counts.loc[donor] = counts[keep_genes, subsampled_cells].X.A.sum(axis=1).ravel()
    # subsample reads
    if (args.percent_reads < 100):
        donor_counts.loc[donor] = np.random.binomial(donor_counts.loc[donor],
                                            args.percent_reads / 100)

# Tranpose to a Genes x Donors table
gene_counts = donor_counts.T
gene_counts.index.name = 'gene'

# drop unknown genes
prefilter = len(gene_counts)
missing = gene_counts.index[~ gene_counts.index.isin(gene_info.index)]
gene_counts = gene_counts[gene_counts.index.isin(gene_info.index)]
postfilter = len(gene_counts)
if prefilter != postfilter:
    print(f"Gene counts reduced from {prefilter} to {postfilter} genes based on known symbols")

# add other columns
gene_counts["chr"] = 'chr' + gene_counts.index.map(gene_info.seqname).astype(str)
gene_counts["start"] = gene_counts.index.map(gene_info.TSS)
gene_counts["end"] = gene_counts.index.map(gene_info.TSS) + 1
gene_counts["strand"] = gene_counts.index.map(gene_info.strand)

gene_counts = gene_counts.reset_index()["chr start end gene gene strand".split() +
                                        donor_counts.index.tolist()]
gene_counts.columns = "#chr start end gid pid strand".split() + donor_counts.index.tolist()
gene_counts.to_csv(args.output, sep="\t", index=None)
