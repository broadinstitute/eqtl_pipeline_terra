version 1.0
task filter_plink {
  input {
    File plink_bed
    File plink_bim
    File plink_fam
    File variants_to_keep
  }

  Float bed_size = size(plink_bed, "GiB")
  Int disk = ceil(10.0 + 4.0 * bed_size)

  command {
    set -euo pipefail
    plink2 \
        --extract ${variants_to_keep} \
        --bed ${plink_bed} \
        --bim ${plink_bim} \
        --fam ${plink_fam} \
        --make-bed \
        --out keep_variants
  }

  output {
    File bed = "keep_variants.bed"
    File bim = "keep_variants.bim"
    File fam = "keep_variants.fam"
  }

  runtime {
    docker: "briansha/plink2:terra"
    memory: "32 GiB"
    disks: "local-disk " + disk + " HDD"
    cpu: 4
    preemptible: 1
    maxRetries: 0
  }
}
