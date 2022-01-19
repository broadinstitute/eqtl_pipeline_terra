import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow make_qc_plots_workflow {

    File counts
    String output_gs_dir
    String dir_name = ""
    String plot_prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    call umis_per_cell {
        input:
            counts=counts,
            plot_prefix=plot_prefix,
            memory=memory, 
            disk_space=disk_space, 
            num_threads=num_threads, 
            num_preempt=num_preempt, 
    }

    call copy2bucket.CopyFiles2Directory as copy_1 {
        input: 
            files_2_copy=[umis_per_cell.umi_cell_png],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

    call cells_per_donor {
        input:
            counts=counts,
            plot_prefix=plot_prefix,
            memory=memory, 
            disk_space=disk_space, 
            num_threads=num_threads, 
            num_preempt=num_preempt, 
    }

    call copy2bucket.CopyFiles2Directory as copy_2 {
        input: 
            files_2_copy=[cells_per_donor.cell_donor_png],
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

}

task umis_per_cell {
    
    File counts
    String plot_prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        python /umis_per_cell.py ${counts} ${plot_prefix}
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest"
    }

    output {
        File umi_cell_png="${plot_prefix}.umis_per_cell.png"
    }

}

task cells_per_donor {
    
    File counts
    File cell_donor_map
    String plot_prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        python /cells_per_donor.py ${counts} ${cell_donor_map} ${plot_prefix}
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    output {
        File cell_donor_png="${plot_prefix}.cells_per_donor.png"
    }

}


	2. 02_filter_cells_donors
		a. Downsample/cap high-UMI cells
		b. Remove cells not assigned to donor
		c. Remove donors with not enough cells
