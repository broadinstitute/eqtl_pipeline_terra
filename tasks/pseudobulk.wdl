version 1.0
# given a group_name, go through given files and extract/pseudobulk anything corresponding to that village
# TODO fix this to not use cp
task pseudobulk {
  input {
    String group_name # ex. ips_D0
    Array[String] sample_ids # ex. ips_D0
    Array[File] cell_donor_map # ex. '${sample_id}_cell_to_donor.txt'
    Array[File] cell_group_map # ex. ${sample_id}_cell_to_group.txt'
    Array[File] h5ad # ex. '${sample_id}_singlets_cbc_suffix.h5ad'
    
    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  command {
    set -euo pipefail
    python /pseudobulk.py ${group_name} \
              -s ${sep=' ' sample_ids} \
              -d ${sep=' ' cell_donor_map} \
              -g ${sep=' ' cell_group_map} \
              -h ${sep=' ' h5ad} 
  }

  runtime {
    docker: docker_image
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File cell_donor_map_group='${group_name}_cell_to_donor.txt'
    File counts='${group_name}_counts.h5ad'
  }
}