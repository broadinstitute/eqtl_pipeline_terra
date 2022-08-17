version 1.0
task qc_plots {
  input {
    File counts
    File cell_donor_map
    String prefix
    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8'

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  command {
    set -euo pipefail
    pip install anndata==0.8

    python <<CODE
    import pandas as pd
    import anndata
    import matplotlib.pyplot as plt

    # load counts
    counts = anndata.read_h5ad('${counts}')

    # plot umis per cell
    reads_all = counts.X.sum(axis=1).A.ravel()
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(reads_all, bins=100)
    ax.set_xlabel('# UMIs / cell')
    ax.set_ylabel('# cells')
    fig.patch.set_facecolor('w')
    plt.savefig('${prefix}.umis_per_cell.png', dpi=300)

    # load cell to donor map
    cell_to_donor = pd.read_table('${cell_donor_map}')
    cell_to_donor.columns = "cell donor".split()

    # filter to cells that exist (cells in the count matrix)
    cell_to_donor = cell_to_donor[cell_to_donor.cell.isin(counts.obs_names)]

    # plot genes per cell
    fig,ax = plt.subplots(facecolor='w')
    ax.hist((counts.X != 0).sum(axis=1).A.ravel(), bins=100)
    ax.set_xlabel('# genes / cell')
    ax.set_ylabel('# cells')
    fig.patch.set_facecolor('w')
    plt.savefig('${prefix}.genes_per_cell.png', dpi=300)

    # plot cells per donor
    fig,ax = plt.subplots(facecolor='w')
    ax.hist(cell_to_donor['donor'].value_counts().values, bins=30)
    ax.set_xlabel('# cells / donor')
    ax.set_ylabel('# donors')
    fig.patch.set_facecolor('w')
    plt.savefig('${prefix}.cells_per_donor.png', dpi=300)

    CODE
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
            help: '# UMIs / cell histogram',
            example: 'ips_D0.umis_per_cell.png'
        }
    gene_cell_png: {
            description: '# genes / cell histogram',
            help: '# genes / cell histogram',
            example: 'ips_D0.genes_per_cell.png'
        }
    cell_donor_png: {
            description: '# cells / donor histogram',
            help: '# cells / donor histogram',
            example: 'ips_D0.cells_per_donor.png'
        }
  }


}
