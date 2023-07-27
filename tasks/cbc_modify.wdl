version 1.0
# add suffix to the cell barcodes so they are unique before pseudobulking

task cbc_modify {
  input {
    String sample_id # ex. ips_D0_CIRM12_1
    String group_name # ex. ips_D0
    File h5 # ex. ips_D0_CIRM12_2_out_singlets_only.h5ad 
    File cell_donor_assignments # ex. ips_D0_CIRM12_2_donor_assignments.txt

    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:latest'
  }

  String out_h5 = "./renamed_" + basename(h5)
  String out_donorassign = "./renamed_" + basename(cell_donor_assignments)

  command {
    set -euo pipefail

    pip install scanpy

    python <<EOF
import anndata as ad
import pandas as pd

counts = ad.read_h5ad("${h5}")
counts['cell'] += '-${sample_id}'
counts.write(${out_h5})

assignments = pd.read_table("${cell_donor_assignments}", comment='#')
assignments['group_name'] = '${group_name}'
assignments['cell'] = assignments['cell']  + '-${sample_id}'
assignments.to_csv("${out_donorassign}", sep="\t", index=False)

EOF
  }

  runtime {
    docker: docker_image
  }

  output {
    File renamed_cell_donor_assingments=out_donorassign
    File h5ad_renamed=outfile
  }
}
