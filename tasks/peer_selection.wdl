version 1.0
# TODO add parameter meta

task peer_selection {
  input {
    Array[File] cis_eqtl_results
    Int n_chosen_peers=5
    String prefix

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'
  }

  command {
    set -euo pipefail
    python /peer_selection.py ${prefix} ${sep=' ' cis_eqtl_results}
  }

  runtime {
    docker: docker_image
  }
  
  output {
    File peer_png="${prefix}.PEER_selection.png"
    File chosen_peer_txt="/**/${prefix}.${n_chosen_peers}PEERs.cis_qtl.txt.gz"
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
