import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(dest="prefix", type=str,
                        help="prefix for png, ex. group/village name")
    parser.add_argument(dest="n_chosen_peers", type=int,
                        help="chosen number of peers to make a cis-eqtl parquet file for")
    parser.add_argument(dest="fdr", type=float, default=0.05,
                        help="the false discovery rate threshold to call significant eqtls")
    parser.add_argument("-r", dest="cis_eqtl_results", nargs='+', default=[], 
                        help="Array of files of cis-eQTL results")
    parser.add_argument("-c", dest="covariates", nargs='+', default=[], 
                        help="Array of files of combined covariates")
    args = parser.parse_args()

    peer_range = []
    n_qtls = []
    for file in args.cis_eqtl_results:
      # TODO assert that the file matches this naming format
      # get number of peers for this file 
      basename = os.path.basename(file)
      n_peer = int(basename.replace(f'{args.prefix}.','').replace('PEERs.cis_qtl.txt.gz',''))
      peer_range.append(n_peer)

      # load qtl results
      df = pd.read_csv(file, sep='\t')
      n_qtls.append( (df['qval']<=0.05).sum() )

      # for the chosen number of peers, 
      if n_peer == args.n_chosen_peers:
        # call significant eQTLs
        df = df.query('qval<=@args.fdr')

        # save the chosen qtl result file as parquet for fine-mapping step
        df.to_parquet(f'{args.prefix}.{n_peer}PEERs.cis_qtl.sigificant.parquet')

        # save the combined covariates, I don't get the file paths so 
        filename = [s for s in args.covariates if f'.{str(n_peer)}PEERs' in s][0]
        cov_df = pd.read_csv(filename, sep='\t')
        cov_df.to_csv(f'{args.prefix}.{n_peer}PEERs.combined_covariates.txt', sep='\t', index=False)

    # sort array 
    n_qtls = [n for _,n in sorted(zip(peer_range,n_qtls))]
    peer_range = sorted(peer_range)

    # PEER plot (choose the # of PEERs that maximizes discovery)
    fig,ax = plt.subplots()
    ax.scatter(peer_range, n_qtls);
    ax.plot(peer_range, n_qtls);
    ax.set_ylim(bottom=0);
    ax.set_xlabel('# PEERs'); 
    ax.set_ylabel('# eQTLs');
    fig.patch.set_facecolor('w')
    plt.savefig(f'{args.prefix}.PEER_selection.png', dpi=300)
