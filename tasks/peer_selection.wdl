version 1.0
# TODO add parameter meta
# TODO add covariate file selection
# TODO make it output a cis-eqtl parquet file for fine-mapping step
task peer_selection {
  input {
    Array[File] cis_eqtl_results
    Array[File] covariates
    Int n_chosen_peers=5
    String prefix

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'
  }

  command {
    set -euo pipefail
    python /peer_selection.py ${prefix} ${n_chosen_peers} \
                    -r ${sep=' ' cis_eqtl_results} \
                    -c ${sep=' ' covariates} \
                    
  }

  runtime {
    docker: docker_image
  }

  output {
    File peer_png="${prefix}.PEER_selection.png"
    File chosen_peer_qtls="${prefix}.${n_chosen_peers}PEERs.cis_qtl.parquet"
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
