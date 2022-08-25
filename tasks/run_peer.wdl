version 1.0
# TODO add parameter_meta
task all_peer_factors {
  input {
    File expression_file
    String prefix
    Int n_all_peers

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  command {
    set -euo pipefail
    Rscript /src/run_PEER.R ${expression_file} ${prefix} ${n_all_peers}
  }

  runtime {
    docker: "gcr.io/broad-cga-francois-gtex/gtex_eqtl:V9"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File peer_covariates="${prefix}.PEER_covariates.txt"
    File alpha="${prefix}.PEER_alpha.txt"
  }

}

task subset_peers_and_combine {
  input {
    File peer_covariates
    String prefix
    Int n_peer

    File? genotype_pcs
    File? add_covariates

    Int memory=64
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  command {
    set -euo pipefail
    head -n ${n_peer+1} ${peer_covariates} > ${prefix}.${n_peer}PEER_subset.PEER_covariates.txt
    /src/combine_covariates.py ${prefix}.${n_peer}PEER_subset.PEER_covariates.txt ${prefix}.${n_peer}PEERs ${"--genotype_pcs " + genotype_pcs} ${"--add_covariates " + add_covariates}
  }

  runtime {
    docker: "gcr.io/broad-cga-francois-gtex/gtex_eqtl:V9"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File combined_covariates="${prefix}.${n_peer}PEERs.combined_covariates.txt"
  }

}


