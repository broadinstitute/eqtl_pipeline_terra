version 1.0
task pseudobulk {
  input {
    Array[File] cell_donor_map # ex. '${sample_id}_cell_to_donor.txt'
    Array[File] cell_group_map # ex. ${sample_id}_to_${group_name}_cell_to_group.txt'
    Array[File] h5ad # ex. '${sample_id}_singlets_cbc_suffix.h5ad'
    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'
  }

  command {
    set -euo pipefail
    
  }

  runtime {
    docker: docker_image
  }

  output {
    File cell_donor_map='${sample_id}_cell_to_donor.txt'
  }
}