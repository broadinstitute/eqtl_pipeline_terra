version 1.0

# import other WDLs
import "tasks/qc_plots.wdl" as qc
import "tasks/filter_cells_donors.wdl" as filter
import "tasks/normalize.wdl" as normalize

# This workflow takes pseudobulked data and maps eQTLs
workflow village_qtls {
  input {
    File counts
    File cell_donor_map
    File gene_gtf
    String prefix
  }

  call qc.qc_plots as qc_plots {
    input:
      counts=counts, 
      cell_donor_map=cell_donor_map,
      prefix=prefix,
  }

  call filter.filter as filter_cells_donors {
    input:
      counts=counts, 
      cell_donor_map=cell_donor_map,
      gene_gtf=gene_gtf,
      prefix=prefix,
  }
}