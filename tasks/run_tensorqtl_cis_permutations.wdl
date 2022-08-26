version 1.0
# TODO add parameter_meta
task tensorqtl_cis_permutations {
  input {
    File plink_bed
    File plink_bim
    File plink_fam

    File phenotype_bed
    File covariates
    String prefix = basename(covariates, ".combined_covariates.txt")

    File? phenotype_groups
    Float? fdr
    Float? qvalue_lambda
    Float? maf_thresh

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }
  
  command {
    plink_base=$(echo "${plink_bed}" | rev | cut -f 2- -d '.' | rev)
    python3 -m tensorqtl \
      $plink_base ${phenotype_bed} ${prefix} \
      --mode cis \
      --covariates ${covariates} \
      ${"--phenotype_groups " + phenotype_groups} \
      ${"--fdr " + fdr} \
      ${"--qvalue_lambda " + qvalue_lambda}
      ${"--maf_threshold " + maf_thresh}
  }

  output {
    File cis_qtl="${prefix}.cis_qtl.txt.gz"
    File log="${prefix}.tensorQTL.cis.log"
  }

  runtime {
    docker: "gcr.io/broad-cga-francois-gtex/tensorqtl:latest"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    bootDiskSizeGb: 25
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
    gpuType: "nvidia-tesla-p100"
    gpuCount: 1
    zones: ["us-central1-c"]
  }
  
  meta {
    author: "Francois Aguet"
  }
}