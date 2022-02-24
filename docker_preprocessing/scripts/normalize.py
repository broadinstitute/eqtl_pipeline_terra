import sys
import pandas as pd
import qtl
from qtl import norm
import argparse

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(dest="counts", type=str,
                        help="genes x donors count matrix")
    parser.add_argument(dest="output_prefix", type=str,
                        help="prefix for output files")
    args = parser.parse_args()


    # read in genes x donors count matrix
    gene_counts = pd.read_csv(args.counts, sep="\t", index_col=None)

    # sort 
    gene_counts = gene_counts.sort_values(['#chr','start']).rename({'gid':'gene_id'}, axis=1).set_index('gene_id') # Sort [chr1, chr10,..chr2, chr20,.., chr3,..chr9]
    
    # TPM normalization
    norm_df = qtl.norm.edger_cpm(gene_counts.iloc[:,5:])

    out_df = gene_counts.iloc[:,:4].join(norm_df) # prepare output parquet/bed
    out_df = out_df.sort_values(['#chr','start'])
    out_df = out_df.rename({'gid':'gene_id'}, axis=1)

    out_file = f'{args.output_prefix}.TPM_expression' # write out parquet & bed files
    out_df.to_parquet(out_file+'.parquet')
    out_df.to_csv(out_file+'.bed', sep='\t', index=False)

    # inverse normal transform
    phenotype_df = qtl.norm.inverse_normal_transform(norm_df)

    out_df = gene_counts.iloc[:,:4].join(phenotype_df) # prepare output parquet/bed
    out_df = out_df.sort_values(['#chr','start'])
    out_df = out_df.rename({'gid':'gene_id'}, axis=1)

    out_file = f'{args.output_prefix}.normalized_expression' # write out parquet & bed files
    out_df.to_parquet(out_file+'.parquet')
    out_df.to_csv(out_file+'.bed', sep='\t', index=False)
