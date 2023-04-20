version 1.0
# annotate with sldsc

task annotate_ldsc {
  input {
    File variant_file # variants should be in the format of chr:pos:ref:alt (instead of chr_pos_ref_alt)
    File ldsc 

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'

  }
  command {
    set -euo pipefail
    wget gs://broad-alkesgroup-public-requester-pays/LDSCORE/GRCh38/baselineLD_v2.2.tgz
    tar zxvf baselineLD_v2.2.tgz
  }
  
  runtime {
    docker: docker_image
  }

  output {
    # File cell_donor_map='${sample_id}_cell_to_donor.txt'
    # File cell_group_map='${sample_id}_cell_to_group.txt'
    # File h5ad_renamed='${sample_id}_singlets_cbc_suffix.h5ad'
  }
}