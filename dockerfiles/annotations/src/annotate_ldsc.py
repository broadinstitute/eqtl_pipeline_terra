import pandas as pd

if __name__ == '__main__':

  parser = argparse.ArgumentParser()
  parser.add_argument(dest="counts", type=str,
                      help="H5AD file of counts")
  parser.add_argument(dest="donormap", type=str,
                      help="cell to donor assignments")
  parser.add_argument(dest="sample_id", type=str,
                      help="sample name")
  parser.add_argument(dest="group_name", type=str,
                      help="group/village name")
  args = parser.parse_args()


  # import the fine-mapped list
  cohort_id = 'MTB'
  fm_df = pd.read_csv(f'/mnt/DATA1/macrophage_eqtls/qtl_mapping/{cohort_id}.finemap.cis_qtl.txt.gz', sep='\t')

  # parse the variant id
  fm_df = fm_df.join(fm_df['index'].str.split('_', expand=True).iloc[:,0:2]).rename({0:'chrom', 1:'pos'}, axis=1)
  fm_df['pos'] = fm_df['pos'].astype(int)

  annot_dfs = {}
  num = 0; den = 0
  res_df = pd.DataFrame([])

  for chrom in range(1,23):
      annot_dfs[chrom] = pd.read_csv(f'/mnt/DATA1/resources/LDSCORE/baselineLD_v2.2/baselineLD.{chrom}.annot.gz', sep='\t')
      fm_df_chr = fm_df[fm_df['chrom']==f'chr{chrom}']
      
      num += sum(fm_df_chr['pos'].isin(annot_dfs[chrom]['BP']))
      den += len(fm_df_chr)
      
      df_new = pd.merge(fm_df_chr, annot_dfs[chrom], how='left', left_on='pos', right_on='BP').drop('chrom pos CHR BP'.split(), axis=1)
      res_df = pd.concat([res_df, df_new])

  print(f'{num/den*100:.2f}% ({num} of {den}) SNPs have a corresponding annotation')

  res_df.to_csv(f'/mnt/DATA1/macrophage_eqtls/annotations/{cohort_id}.finemap.ldscore.annot.cis_qtl.txt.gz', sep='\t')

