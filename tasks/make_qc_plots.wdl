import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow make_qc_plots_workflow {

    File counts
    File cell_donor_map
    String plot_prefix

    String output_gs_dir
    String dir_name = ""

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    call qc_plots {
        input:
            counts=counts,
            cell_donor_map=cell_donor_map,
            plot_prefix=plot_prefix,
            memory=memory, 
            disk_space=disk_space, 
            num_threads=num_threads, 
            num_preempt=num_preempt, 
    }

    call copy2bucket.CopyFiles2Directory as copy_1 {
        input: 
            files_2_copy=[qc_plots.umi_cell_png,qc_plots.gene_cell_png,qc_plots.cell_donor_png],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

}

task qc_plots {
    
    File counts
    File cell_donor_map
    String plot_prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        python /plot.py ${counts} ${cell_donor_map} ${plot_prefix}
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    output {
        File umi_cell_png="${plot_prefix}.umis_per_cell.png"
        File gene_cell_png="${plot_prefix}.genes_per_cell.png"
        File cell_donor_png="${plot_prefix}.cells_per_donor.png"
    }

}
