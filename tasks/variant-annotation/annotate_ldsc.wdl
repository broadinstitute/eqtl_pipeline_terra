version 1.0
# annotate with ldsc

task annotate_ldsc {
  input {
    File variant_file # variants should be in the format of chr:pos:ref:alt (instead of chr_pos_ref_alt)
    String variant_file_basename = basename(variant_file, ".parquet") 

    File ldsc_tar='gs://broad-alkesgroup-public-requester-pays/LDSCORE/GRCh38/baselineLD_v2.2.tgz'

    String docker_image='us.gcr.io/landerlab-atacseq-200218/annotations:latest'

  }
  command {
    set -euo pipefail
    tar zxvf ${ldsc_tar}
    python /annotate_ldsc.py ${variant_file} baselineLD_v2.2 ${variant_file_basename}
  }

  runtime {
    docker: docker_image
  }

  output {
    File ldsc_annot_parquet='${variant_file_basename}.ldsc_annots.parquet'
  }
}