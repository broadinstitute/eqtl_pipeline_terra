version 1.0
# add suffix to the cell barcodes so they are unique before pseudobulking
# TODO add parameter meta

task cbc_modify {
  input {
    String sample_id # ex. ips_D0_CIRM12_1
    String group_name # ex. ips_D0
    File h5ad_filtered # ex. ips_D0_CIRM12_2_out_singlets_only.h5ad 
    File cell_donor_assignments # ex. ips_D0_CIRM12_2_donor_assignments.txt

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'
  }
  command {
    set -euo pipefail
    python /cbc_modify.py ${h5ad_filtered} ${cell_donor_assignments} ${sample_id} ${group_name}
  }

  runtime {
    docker: docker_image
  }

  output {
    File cell_donor_map='${sample_id}_cell_to_donor.txt'
    File cell_group_map='${sample_id}_cell_to_group.txt'
    File h5ad_renamed='${sample_id}_singlets_cbc_suffix.h5ad'
  }
}