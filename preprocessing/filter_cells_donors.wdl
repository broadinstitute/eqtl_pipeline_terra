import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow filter_workflow {

    File counts
    File cell_donor_map
    Int? cell_per_donor_threshold
    Int? umis_per_cell_threshold
    File? donor_list
    File? gene_list
    File gene_gtf
    String prefix

    String output_gs_dir
    String dir_name = ""

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    call filter {
        input:
            counts=counts,
            cell_donor_map=cell_donor_map,
            cell_per_donor_threshold=cell_per_donor_threshold,
            umis_per_cell_threshold=umis_per_cell_threshold,
            donor_list=donor_list,
            gene_list=gene_list,
            gene_gtf=gene_gtf,
            prefix=prefix,
            memory=memory, 
            disk_space=disk_space, 
            num_threads=num_threads, 
            num_preempt=num_preempt, 
    }

    call copy2bucket.CopyFiles2Directory as copy_1 {
        input: 
            files_2_copy=[filter.umi_cell_post_png, filter.counts_filtered],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

    call normalize {
        input:
            counts_filtered=filter.counts_filtered,
            prefix=prefix,
    }

    call copy2bucket.CopyFiles2Directory as copy_2 {
        input: 
            files_2_copy=[normalize.parquet_tpm, normalize.bed_tpm, normalize.parquet_int, normalize.bed_int],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

    call index as index_tpm {
        input:
            bed=normalize.bed_tpm,
    }

    call index as index_int {
        input:
            bed=normalize.bed_int,
    }

    call copy2bucket.CopyFiles2Directory as copy_3 {
        input: 
            files_2_copy=[index_tpm.bed_gz, index_tpm.index, index_int.bed_gz, index_int.index],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

}

task filter {
    
    File counts
    File cell_donor_map
    Int? cell_per_donor_threshold
    Int? umis_per_cell_threshold
    File? donor_list
    File? gene_list
    File gene_gtf
    String prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        python /filter.py --donors ${default="ALL" donor_list} --genes ${default="ALL" gene_list} --thresh-umis ${default="0" umis_per_cell_threshold} \
        --thresh-cells ${default="0" cell_per_donor_threshold} ${counts} ${cell_donor_map} ${prefix} ${gene_gtf}
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    output {
        File umi_cell_post_png="${prefix}.umis_per_cell.postfilter.png"
        File counts_filtered="${prefix}.counts.filtered.txt"
    }

}

task normalize {
    
    File counts_filtered
    String prefix

    command {
        set -euo pipefail
        python /normalize.py ${counts_filtered} ${prefix}
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8"
    }

    output {
        File parquet_tpm="${prefix}.TPM_expression.parquet"
        File bed_tpm="${prefix}.TPM_expression.bed"
        File parquet_int="${prefix}.normalized_expression.parquet"
        File bed_int="${prefix}.normalized_expression.bed"
    }

}

task index {

    File bed
    String prefix = basename(bed, ".bed")

    command {
        set -euo pipefail
        bgzip < ${bed} > ${prefix}.bed.gz
        tabix -p bed ${prefix}.bed.gz
    }

    runtime {
        docker: "quay.io/biocontainers/samtools:1.10--h2e538c0_3"
    }

    output {
        File bed_gz="${prefix}.bed.gz"
        File index="${prefix}.bed.gz.tbi"
    }

}
