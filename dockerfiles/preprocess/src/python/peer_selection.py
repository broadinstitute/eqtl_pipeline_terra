import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(dest="cis_eqtl_results", type=str,
                        help="Array of files of cis-eQTL results, comma-separated, no spaces")
    parser.add_argument(dest="prefix", type=str,
                        help="prefix for png, ex. group/village name")
    args = parser.parse_args()
    Array[File] cis_eqtl_results
    String prefix

    peer_range = []
    n_qtls = []
    print('${sep=", " cis_eqtl_results}')
    cis_eqtl_results = '${sep="," cis_eqtl_results}'
    file_array = cis_eqtl_results.split(',')
    for file in file_array:
      print(file)
      # TODO assert that the file matches this naming format

      n_peer = int(file.removeprefix('${prefix}.').removesuffix('PEERs.cis_qtl.txt.gz'))
      peer_range.append(n_peer)

      df = pd.read_csv(file, sep='\t')
      n_qtls.append( (df['qval']<=0.05).sum() )

    # PEER plot (chose the # of PEERs that maximizes discovery)
    fig,ax = plt.subplots()
    ax.scatter(peer_range, n_qtls);
    ax.plot(peer_range, n_qtls);
    ax.set_ylim(bottom=0);
    ax.set_xlabel('# PEERs'); 
    ax.set_ylabel('# eQTLs');
    fig.patch.set_facecolor('w')
    plt.savefig('${prefix}.PEER_selection.png', dpi=300)
