version 1.0
# TODO add parameter meta
task peer_selection {
  input {
    Array[File] cis_eqtl_results
    Array[File] covariates
    Int n_chosen_peers=5
    String prefix

    Float fdr=0.05

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:0.1'
  }

  command {
    set -euo pipefail
    python /peer_selection.py ${prefix} ${n_chosen_peers} ${fdr} \
                    -r ${sep=' ' cis_eqtl_results} \
                    -c ${sep=' ' covariates} \
  }

  runtime {
    docker: docker_image
  }

  output {
    File peer_png="${prefix}.PEER_selection.png"
    File chosen_peer_qtls="${prefix}.${n_chosen_peers}PEERs.cis_qtl.sigificant.parquet"
    File chosen_peer_covariates="${prefix}.${n_chosen_peers}PEERs.combined_covariates.txt"
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
