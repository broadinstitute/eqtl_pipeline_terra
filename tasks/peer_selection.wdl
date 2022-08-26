version 1.0
# TODO add parameter meta

workflow run_peer_selection {
  input {
    Array[File] cis_eqtl_results
    Int n_chosen_peers
    String prefix
  }
  call peer_selection {
    input:
    cis_eqtl_results=cis_eqtl_results,
    n_chosen_peers=n_chosen_peers,
    prefix=prefix,
  }
}

task peer_selection {
  input {
    Array[File] cis_eqtl_results
    Int n_chosen_peers
    String prefix
  }

  command {
    set -euo pipefail

    python <<CODE
    import pandas as pd
    import matplotlib.pyplot as plt
    import numpy as np

    peer_range = []
    n_qtls = []
    for file in '${sep=", " cis_eqtl_results}':
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

    CODE
  }

  output {
    File peer_png="${prefix}.PEER_selection.png"
    File chosen_peer_txt="${prefix}.${n_chosen_peers}PEERs.cis_qtl.txt.gz"
  }

  parameter_meta {
    # Inputs
    prefix: {
            description: 'Prefix (ex. village name)',
            help: 'String for output file prefix',
            example: 'ips_D0'
        }

    # Outputs

  }
}
