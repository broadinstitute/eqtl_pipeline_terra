version 1.0

workflow singlet_filter {
  input {
    File h5
    File doublets
    Float threshold
  }
  call remove_doublets {
    input:
    h5=h5,
    doublets=doublets,
    threshold=threshold
  }
  call filter_to_singlets {
    input:
    h5=h5,
    doublets=doublets,
    threshold=threshold
  }
}

task remove_doublets {
  input {
    File h5 # raw_feature_bc_matrix.h5 from cellranger directory
    File doublets # doublet detection results with "cell" and "sampleOneMixtureRatio"
    Float threshold # mixture ratio cutoff from 0 to 1

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  String outfile = basename(h5, ".h5") + "_no_doublets.h5ad"

  command {
    set -euo pipefail
    pip install scanpy

    python <<CODE
    import pandas as pd
    import numpy as np
    import scanpy as sc

    # doublet results
    doublet_df = pd.read_csv('${doublets}', sep='\t', header=1, usecols=['cell', 'sampleOneMixtureRatio'])

    # doublet CBC to remove
    doublet_CBC = doublet_df['cell'][doublet_df['sampleOneMixtureRatio']<${threshold}].values

    # Read in h5 and filter
    ad = sc.read_10x_h5('${h5}')
    ad = ad[ad.obs_names[~ad.obs_names.isin(doublet_CBC)]] # keep barcodes that are not doublets
    ad.write('${outfile}')

    CODE
  }

  runtime {
    docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File h5ad_filtered=outfile
  }

}

task filter_to_singlets {
  input {
    File h5 # {sample_id}_out.h5 from cellbender output
    File doublets # doublet detection results with "cell" and "sampleOneMixtureRatio"
    Float threshold # mixture ratio cutoff from 0 to 1

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }

  String outfile = basename(h5, ".h5") + "_singlets_only.h5ad"

  command {
    set -euo pipefail
    pip install scanpy

    python <<CODE
    import pandas as pd
    import numpy as np
    import scanpy as sc

    # doublet results
    doublet_df = pd.read_csv('${doublets}', sep='\t', header=1, usecols=['cell', 'sampleOneMixtureRatio'])

    # singlet CBC to keep
    singlet_CBC = doublet_df['cell'][doublet_df['sampleOneMixtureRatio']>${threshold}].values

    # Read in h5 and filter
    ad = sc.read_10x_h5('${h5}')
    ad = ad[ad.obs_names[ad.obs_names.isin(singlet_CBC)]] # keep barcodes that are singlets
    ad.write('${outfile}')

    CODE
  }

  runtime {
    docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File h5ad_filtered=outfile
  }

}

