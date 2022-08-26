version 1.0
# TOSO add parameter meta

workflow peer_plot_selection {
  call peer_selection
}

task peer_selection {
  input {
    Array[Int] peer_range
    Array[File] cis_eqtl_results
    Int n_chosen_peers
    String prefix
  }

  command {
    set -euo pipefail

    python <<CODE
    import pandas as pd
    import matplotlib.pyplot as plt

    # peer_range = np.int('${peer_range}')
    dfs = {}
    n_qtls = []
    for n_peer in '${peer_range}':
        dfs[n_peer] = pd.read_csv(f'${prefix}.{n_peer}PEERs.cis_qtl.txt.gz', sep='\t')
        n_qtls.append( (dfs[n_peer]['qval']<=0.05).sum() )

    # PEER plot (chose the # of PEERs that maximizes discovery)
    fig,ax = plt.subplots()
    ax.scatter('${peer_range}', n_qtls);
    ax.plot('${peer_range}', n_qtls);
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
