version 1.0

# import other WDLs
import "tasks/qc_plots.wdl" as qc
import "tasks/copy_to_google_bucket.wdl" as copy2bucket

workflow make_qc_plots_workflow {
  input {
    File counts
    File cell_donor_map
    String prefix

    String output_gs_dir
    String dir_name = ""
  }

  call qc_plots {
    input:
      counts=counts,
      cell_donor_map=cell_donor_map,
      prefix=prefix,
  }

  call copy2bucket.CopyFiles2Directory as copy_1 {
    input: 
      files_2_copy=[qc_plots.umi_cell_png,qc_plots.gene_cell_png,qc_plots.cell_donor_png],
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

}
