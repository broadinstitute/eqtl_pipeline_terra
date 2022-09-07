version 1.0
# TODO change this back to calling the python script
task qc_plots {
  input {
    File counts
    File cell_donor_map
    String prefix
    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  command {
    set -euo pipefail
    python /qc_plots.py ${counts} ${cell_donor_map} ${prefix}
  }

  runtime {
    docker: docker_image
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File umi_cell_png="${prefix}.umis_per_cell.png"
    File gene_cell_png="${prefix}.genes_per_cell.png"
    File cell_donor_png="${prefix}.cells_per_donor.png"
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
    umi_cell_png: {
            description: '# UMIs / cell histogram',
            help: 'PNG image of # UMIs / cell histogram',
            example: 'ips_D0.umis_per_cell.png'
        }
    gene_cell_png: {
            description: '# genes / cell histogram',
            help: 'PNG image of # genes / cell histogram',
            example: 'ips_D0.genes_per_cell.png'
        }
    cell_donor_png: {
            description: '# cells / donor histogram',
            help: 'PNG image of # cells / donor histogram',
            example: 'ips_D0.cells_per_donor.png'
        }
  }
}
