import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow tensorqtl_cis_permutations_peers_workflow {
    
    Array[File] covariates_files

    String output_gs_dir
    String dir_name = ""

    scatter(file in covariates_files) {
        call tensorqtl_cis_permutations {
            input: 
                covariates=file, 
        }
    }

    call copy2bucket.CopyFiles2Directory as copy_1 {
        input: 
            files_2_copy=tensorqtl_cis_permutations.cis_qtl,
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

}

task tensorqtl_cis_permutations {
    
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

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

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