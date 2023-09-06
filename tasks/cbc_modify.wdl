version 1.0
# add suffix to the cell barcodes so they are unique before pseudobulking

task cbc_modify {
  input {
    String sample_id # ex. ips_D0_CIRM12_1
    String group_name # ex. ips_D0
    File h5 # ex. filtered_feature_bc_matrix.h5
    File cell_donor_assignments # ex. ips_D0_CIRM12_2_donor_assignments.txt

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'
  }

  String out_h5 = "./renamed_" + basename(h5)
  String out_cell_to_donor = basename(sample_id) + "_cell_to_donor.txt"
  String out_cell_to_group = basename(sample_id) + "_cell_to_group.txt"


  command {
    set -euo pipefail

    pip install scanpy

    python -u <<EOF
import anndata as ad
import pandas as pd
import scanpy as sc

print("Starting up cbc modify.")
counts = sc.read_10x_h5("${h5}")
print("h5 successfully loaded.")

# filter to singlets
assignments = pd.read_table("${cell_donor_assignments}")
counts = counts[assignments.barcode, :]

counts.obs.index += '-${sample_id}'
print("Saving off subset h5ad.")
counts.write_h5ad("${out_h5}")

assignments['group_name'] = '${group_name}'
assignments['cell'] = assignments['barcode']  + '-${sample_id}'

cell_donor_maps = assignments[['cell', 'bestSample']]
cell_group_maps = assignments[['cell', 'group_name']]

print("Saving off cell maps.")
cell_donor_maps.to_csv('${out_cell_to_donor}', sep='\t', index=False)
cell_group_maps.to_csv('${out_cell_to_group}', sep='\t', index=False)
print("Done.")

EOF
  }

  runtime {
    docker: docker_image
    memory: "32GB"
  }

  output {
    File cell_donor_map=out_cell_to_donor
    File cell_group_map=out_cell_to_group
    File h5ad_renamed=out_h5
  }
}
