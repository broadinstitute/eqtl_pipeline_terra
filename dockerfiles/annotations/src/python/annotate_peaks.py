import pandas as pd
import argparse
# TODO add log that returns the pct annotation print statement

if __name__ == '__main__':

  parser = argparse.ArgumentParser()
  parser.add_argument(dest="var_list", type=str,
                      help="file of variants")
  parser.add_argument(dest="ldscore_fpath", type=str,
                      help="file path to baselineLD_v2.2 folder")
  parser.add_argument(dest="variant_file_basename", type=str,
                      help="var_list without filepath or .parquet suffix")
  args = parser.parse_args()


  # import the fine-mapped list
  # TODO change to accept txt 
  fm_df = pd.read_parquet(args.var_list)

  # parse the variant id
  # TODO change to accept ':' and '_' delimiters
  fm_df = fm_df.join(fm_df['variant_id'].str.split(':', expand=True).iloc[:,0:2]).rename({0:'chrom', 1:'pos'}, axis=1)
  fm_df['pos'] = fm_df['pos'].astype(int)

  annot_dfs = {}
  num = 0; den = 0
  res_df = pd.DataFrame([])

  for chrom in range(1,3):
      annot_dfs[chrom] = pd.read_csv(f'{args.ldscore_fpath}/baselineLD.{chrom}.annot.gz', sep='\t')
      fm_df_chr = fm_df[fm_df['chrom']==f'chr{chrom}']
      
      num += sum(fm_df_chr['pos'].isin(annot_dfs[chrom]['BP']))
      den += len(fm_df_chr)
      
      df_new = pd.merge(fm_df_chr, annot_dfs[chrom], how='left', left_on='pos', right_on='BP').drop('chrom pos CHR BP'.split(), axis=1)
      res_df = pd.concat([res_df, df_new])


  res_df.to_csv(f'{args.variant_file_basename}.ldsc_annots.parquet')

