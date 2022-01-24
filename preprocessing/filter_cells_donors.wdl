import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow filter_workflow {

    File counts
    File cell_donor_map
    Int cell_per_donor_threshold
    File gene_list
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
            files_2_copy=[normalize.parquet, normalize.bed],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

    call index {
        input:
            bed=normalize.bed,
            prefix=prefix,
    }

    call copy2bucket.CopyFiles2Directory as copy_3 {
        input: 
            files_2_copy=[index.bed_gz, index.index],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

}

task filter {
    
    File counts
    File cell_donor_map
    Int cell_per_donor_threshold
    File gene_list
    File gene_gtf
    String prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        python /filter.py ${counts} ${cell_donor_map} ${cell_per_donor_threshold} ${gene_list} ${gene_gtf} ${prefix}
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v3"
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
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v4"
    }

    output {
        File parquet="${prefix}.normalized_expression.parquet"
        File bed="${prefix}.normalized_expression.bed"
    }

}

task index {

    File bed
    String prefix

    command {
        set -euo pipefail
        bgzip < ${bed} > ${prefix}.normalized_expression.bed.gz
        tabix -p bed ${prefix}.normalized_expression.bed.gz
    }

    runtime {
        docker: "quay.io/biocontainers/samtools:1.10--h2e538c0_3"
    }

    output {
        File bed_gz="${prefix}.normalized_expression.bed.gz"
        File index="${prefix}.normalized_expression.bed.gz.tbi"
    }

}
