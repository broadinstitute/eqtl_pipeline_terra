import sys
import pandas as pd
import qtl
from qtl import norm

if __name__ == '__main__':

    # read in genes x donors count matrix
    gene_counts = pd.read_csv(sys.argv[1], sep="\t", index_col=None)

    # sort & normalize
    gene_counts = gene_counts.sort_values(['#chr','start']).rename({'gid':'gene_id'}, axis=1).set_index('gene_id') # Sort [chr1, chr10,..chr2, chr20,.., chr3,..chr9]
    norm_df = qtl.norm.edger_cpm(gene_counts.iloc[:,5:])
    phenotype_df = qtl.norm.inverse_normal_transform(norm_df)

    # prepare output parquet/bed
    out_df = gene_counts.iloc[:,:4].join(phenotype_df)
    out_df = out_df.sort_values(['#chr','start'])
    out_df = out_df.rename({'gid':'gene_id'}, axis=1)

    # write out parquet & bed files
    out_file = f'{sys.argv[2]}.normalized_expression'
    out_df.to_parquet(out_file+'.parquet')
    out_df.to_csv(out_file+'.bed', sep='\t', index=False)
