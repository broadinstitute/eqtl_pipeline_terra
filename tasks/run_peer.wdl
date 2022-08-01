import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow eqtl_peer_factors_workflow {
    
    Array[Int] peer_range

    String prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    String output_gs_dir
    String dir_name = ""

    call all_peer_factors {
        input:
            prefix=prefix,
            memory=memory, 
            disk_space=disk_space, 
            num_threads=num_threads, 
            num_preempt=num_preempt
    }

    call copy2bucket.CopyFiles2Directory as copy_1 {
        input: 
            files_2_copy=[all_peer_factors.peer_covariates],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

    call copy2bucket.CopyFiles2Directory as copy_2 {
        input: 
            files_2_copy=[all_peer_factors.alpha],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

    scatter (n_peer in peer_range) {
        call subset_peers_and_combine {
            input:
                n_peer=n_peer,
                peer_covariates=all_peer_factors.peer_covariates, 
                prefix=prefix,
                memory=memory, 
                disk_space=disk_space, 
                num_threads=num_threads, 
                num_preempt=num_preempt
        }
    }

    call copy2bucket.CopyFiles2Directory as copy_3 {
        input: 
            files_2_copy=subset_peers_and_combine.combined_covariates,
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

    meta {
        author: "Francois Aguet"
    }

}

task all_peer_factors {
    
    File expression_file
    String prefix
    Int n_all_peers

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        Rscript /src/run_PEER.R ${expression_file} ${prefix} ${n_all_peers}
    }

    runtime {
        docker: "gcr.io/broad-cga-francois-gtex/gtex_eqtl:V9"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    output {
        File peer_covariates="${prefix}.PEER_covariates.txt"
        File alpha="${prefix}.PEER_alpha.txt"
    }

}

task subset_peers_and_combine {

    File peer_covariates
    String prefix
    Int n_peer

    File? genotype_pcs
    File? add_covariates

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        head -n ${n_peer+1} ${peer_covariates} > ${prefix}.${n_peer}PEER_subset.PEER_covariates.txt
        /src/combine_covariates.py ${prefix}.${n_peer}PEER_subset.PEER_covariates.txt ${prefix}.${n_peer}PEERs ${"--genotype_pcs " + genotype_pcs} ${"--add_covariates " + add_covariates}
    }

    runtime {
        docker: "gcr.io/broad-cga-francois-gtex/gtex_eqtl:V9"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    output {
        File combined_covariates="${prefix}.${n_peer}PEERs.combined_covariates.txt"
    }

}


