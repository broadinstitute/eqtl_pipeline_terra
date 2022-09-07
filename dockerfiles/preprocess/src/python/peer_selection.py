import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(dest="prefix", type=str,
                        help="prefix for png, ex. group/village name")
    parser.add_argument(dest="cis_eqtl_results", nargs='+', default=[], 
                        help="Array of files of cis-eQTL results")
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
