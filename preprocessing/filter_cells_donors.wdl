import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow filter_workflow {

    File counts
    File cell_donor_map
    Int cell_per_donor_threshold
    File gene_list
    File gene_gtf
    String plot_prefix

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
            plot_prefix=plot_prefix,
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

}

task filter {
    
    File counts
    File cell_donor_map
    Int cell_per_donor_threshold
    File gene_list
    File gene_gtf
    String plot_prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        python /filter.py ${counts} ${cell_donor_map} ${cell_per_donor_threshold} ${gene_list} ${gene_gtf} ${plot_prefix}
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v3"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    output {
        File umi_cell_post_png="${plot_prefix}.umis_per_cell.postfilter.png"
        File counts_filtered="${plot_prefix}.counts.filtered.png"
    }

}
