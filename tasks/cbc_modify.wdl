version 1.0
# add suffix to the cell barcodes so they are unique before pseudobulking
# output 
# TODO add parameter meta

task cbc_modify {
  input {
    String sample_id # ex. ips_D0_CIRM12_1
    String group_name # ex. ips_D0
    File h5ad_filtered # ex. ips_D0_CIRM12_2_out_singlets_only.h5ad 
    File cell_donor_assignments # ex. ips_D0_CIRM12_2_donor_assignments.txt

    Int memory=64
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
    import numpy as np

    # load counts
    counts = anndata.read_h5ad('${h5ad_filtered}')

    # Filter and output the cell_to_donor map with new CBC
    cell_to_donor_map = pd.read_csv('${cell_donor_assignments}', 
              sep='\t', skiprows=1, usecols=['cell', 'bestSample'])

    # Filter cell donor map to match the counts matrix (singlets only)
    cell_to_donor_out = cell_to_donor_map.query('cell.isin(@counts.obs.index)')

    # Modify CBC with suffix
    cell_to_donor_out['cell'] += '-${sample_id}'
    cell_to_donor_out.to_csv('${sample_id}_cell_to_donor.txt', sep='\t', index=False)

    # write out the cell to village group mapping
    cell_to_group_out = cell_to_donor_out.set_axis(['cell', 'group_name'], axis=1)
    cell_to_group_out['group_name'] = '${group_name}'
    cell_to_group_out.to_csv('${sample_id}_to_${group_name}_cell_to_group.txt', sep='\t', index=False)

    # update CBC in counts matrix with suffix
    counts.obs.index += '-${sample_id}'
    counts.write('${sample_id}_singlets_cbc_suffix.h5ad')
  }

  runtime {
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File cell_donor_map='${sample_id}_cell_to_donor.txt'
    File cell_group_map='${sample_id}_to_{group_name}_cell_to_group.txt'
    File h5ad_renamed='${sample_id}_singlets_cbc_suffix.h5ad'
  }
}