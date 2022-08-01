import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket_v2/versions/1/plain-WDL/descriptor" as copy2bucket

workflow ref_bias_check_workflow {
    
    Array[File] bams

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    String output_gs_dir
    String dir_name = ""

    scatter (bam in bams) {
        call ref_bias_check {
            input:
                bam=bam,
                memory=memory, 
                disk_space=disk_space, 
                num_threads=num_threads, 
                num_preempt=num_preempt
        }
    }

    call copy2bucket.CopyFiles2Directory {
        input: 
            files_2_copy=ref_bias_check.count_txt,
            output_gs_dir=output_gs_dir,
            dir_name=dir_name,
    }

}

task ref_bias_check {
    
    File regions
    File bam
    String prefix = basename(bam, ".bam")

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        set -euo pipefail
        samtools index ${bam}
        python /count_reads.py ${regions} ${bam} ${prefix}.allele_counts.txt
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/countreads:0.1"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    output {
        File count_txt="${prefix}.allele_counts.txt"
    }

}



