
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
