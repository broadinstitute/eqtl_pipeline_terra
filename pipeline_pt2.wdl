version 1.0

# import other WDLs
import "tasks/qc_plots.wdl" as qc

# This workflow takes pseudobulked data and maps eQTLs
workflow village_qtls {
  input {
    File counts
    File cell_donor_map
    String prefix
  }

  call qc.qc_plots as qc_plots {
    input:
      counts=counts, 
      cell_donor_map=cell_donor_map,
      prefix=prefix,
  }
}