version 1.0
task normalize {
  input {
    File counts_filtered
    String prefix

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8'
  }

  command {
    set -euo pipefail
    python /normalize.py ${counts_filtered} ${prefix}
  }

  runtime {
    docker: docker_image
  }

  output {
    File parquet_tpm="${prefix}.TPM_expression.parquet"
    File bed_tpm="${prefix}.TPM_expression.bed"
    File parquet_int="${prefix}.normalized_expression.parquet"
    File bed_int="${prefix}.normalized_expression.bed"
  }

  parameter_meta {
    # Inputs
    counts_filtered: {
            description: 'Filtered count matrix',
            help: 'TXT file of genes x donors count matrix',
            example: 'ips_D0.counts.filtered.txt'
        }
    prefix: {
            description: 'Prefix (ex. village name)',
            help: 'String for output file prefix',
            example: 'ips_D0'
        }
    docker_image: {
            description: 'Docker image',
            help: 'Docker image for preprocessing. Dependencies: Python 3',
            example: 'us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8'
        }
    
    # Outputs
    parquet_tpm: {
            description: 'TPM normalized count matrix as parquet',
            help: 'Parquet file of TPM-normalized counts in genes x donors matrix',
            example: 'ips_D0.TPM_expression.parquet'
        }
    bed_tpm: {
            description: 'TPM normalized count matrix as BED',
            help: 'BED file of TPM-normalized counts in genes x donors matrix',
            example: 'ips_D0.TPM_expression.bed'
        }
    parquet_int: {
            description: 'Inverse normal transformed count matrix as parquet',
            help: 'Parquet file of inverse normal transform of TPM counts in genes x donors matrix',
            example: 'ips_D0.normalized_expression.parquet'
        }
    bed_int: {
            description: 'Inverse normal transformed count matrix as BED',
            help: 'BED file of inverse normal transform of TPM counts in genes x donors matrix',
            example: 'ips_D0.normalized_expression.bed'
        }
  }
}

task index_bed {
  input {
    File bed
    String bed_basename = basename(bed, ".bed")
  }

  command {
    set -euo pipefail
    bgzip < ${bed} > ${bed_basename}.bed.gz
    tabix -p bed ${bed_basename}.bed.gz
  }

  runtime {
    docker: "quay.io/biocontainers/samtools:1.10--h2e538c0_3"
  }

  output {
    File bed_gz="${bed_basename}.bed.gz"
    File bed_tbi="${bed_basename}.bed.gz.tbi"
  }
}
