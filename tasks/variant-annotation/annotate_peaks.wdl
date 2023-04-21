version 1.0
# annotate with BED files of peaks

task annotate_peaks {
  input {
    File variant_file # variants should be in the format of chr:pos:ref:alt (instead of chr_pos_ref_alt)
    String variant_file_basename = basename(variant_file, ".parquet") 

    Array[File] peaks

    String docker_image='us.gcr.io/landerlab-atacseq-200218/annotations:latest'

  }
  command {
    set -euo pipefail
    python /annotate_peaks.py ${variant_file} baselineLD_v2.2 ${variant_file_basename}
  }

  runtime {
    docker: docker_image
  }

  output {
    File ldsc_annot_parquet='${variant_file_basename}.ldsc_annots.parquet'
  }
}