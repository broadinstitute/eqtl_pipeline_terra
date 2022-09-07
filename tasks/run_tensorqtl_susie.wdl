version 1.0

task tensorqtl_cis_susie {
  input {
    File plink_bed
    File plink_bim
    File plink_fam

    File phenotype_bed
    File covariates
    String prefix
    File cis_output # parquet cis-eqtl output
    Float maf_threshold=0.05

    File? interaction
    File? phenotype_groups

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=0
  }

  command {
    set -euo pipefail
    plink_base=$(echo "${plink_bed}" | rev | cut -f 2- -d '.' | rev)
    python3 -m tensorqtl \
      $plink_base ${phenotype_bed} ${prefix} \
      --mode cis_susie \
      --covariates ${covariates} \
      --cis_output ${cis_output} \
      --maf_threshold ${maf_threshold} \
      ${"--interaction " + interaction} \
      ${"--phenotype_groups " + phenotype_groups}
  }

  runtime {
    docker: "gcr.io/broad-cga-francois-gtex/tensorqtl:latest"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
    gpuType: "nvidia-tesla-p100"
    gpuCount: 1
    zones: ["us-central1-c"]
  }

  output {
    File parquet="${prefix}*.parquet"
    File log=glob("${prefix}*.log")[0]
  }

}
