version 1.0

task filter {
  input {
    File counts
    File cell_donor_map
    File gene_gtf
    String prefix

    File? gene_list # if given gene_list, it will override remove_pct_exp
    File? donor_list

    Int umis_per_cell_threshold=2000
    Int cell_per_donor_threshold=100
    Float remove_pct_exp=50 # remove bottom remove_pct_exp% of genes
    Float downscale_median_factor=2.0
    Array[String]? ignore_chr
    String ignore_chr_pre = if defined(ignore_chr) then "--ignore_chr " else ""

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'

    Int memory=64
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  command {
    set -euo pipefail
    python /filter.py --donors ${donor_list} \
            ${"--genes" + gene_list} \
            ${ignore_chr_pre}${sep=" --ignore_chr " ignore_chr} \
            --remove-pct-exp ${remove_pct_exp} \
            --downscale-median-factor ${downscale_median_factor} \
            --thresh-umis ${umis_per_cell_threshold} \
            --thresh-cells ${cell_per_donor_threshold} \
            ${counts} ${cell_donor_map} ${prefix} ${gene_gtf}
  }

  runtime {
    docker: docker_image
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File umi_cell_post_png="${prefix}.umis_per_cell.postfilter.png"
    File counts_filtered="${prefix}.counts.filtered.txt"
  }

  parameter_meta {
    # Inputs
    counts: {
            description: 'Count matrix',
            help: 'AnnData UMI count matrix (cells x genes)',
            example: 'counts.h5ad'
        }
    cell_donor_map: {
            description: 'Cell to donor map',
            help: 'TXT file of two tab-separated columns with header (header names do not matter). Col 1 = cell barcode, Col 2 = donor.',
            example: 'cell_donor_map.txt'
        }
    gene_gtf: {
            description: 'Gene info',
            help: 'GTF file of gene info',
            example: 'gencode.v26.GRCh38.genes.collapsed_only.gtf'
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

    # TODO: add descriptions of optional input parameters

    # Outputs
    umi_cell_post_png: {
            description: '# UMIs / cell histogram after filtering',
            help: 'PNG image of # UMIs / cell histogram after filtering',
            example: 'ips_D0.umis_per_cell.postfilter.png'
        }
    counts_filtered: {
            description: 'Filtered count matrix',
            help: 'TXT file of genes x donors count matrix',
            example: 'ips_D0.counts.filtered.txt'
        }
  }


}
