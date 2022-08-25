version 1.0

# import other WDLs
import "../tasks/filter_cells_donors.wdl" as filter_cells_donors
import "../tasks/normalize_counts.wdl" as normalize
import "../tasks/copy_to_google_bucket.wdl" as copy2bucket

workflow filter_workflow {
  input {
    File counts
    File cell_donor_map
    File gene_gtf
    String prefix

    String output_gs_dir
    String dir_name = ""
  }

  # Filter
  call filter_cells_donors.filter as filter {
    input:
      counts=counts,
      cell_donor_map=cell_donor_map,
      gene_gtf=gene_gtf,
      prefix=prefix,
  }

  call copy2bucket.CopyFiles2Directory as copy_1 {
    input: 
      files_2_copy=[filter.umi_cell_post_png, filter.counts_filtered],
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

  # Normalize
  call normalize.normalize as normalize_counts {
    input:
      counts_filtered=filter.counts_filtered, 
      prefix=prefix,
  }
  
  call normalize.index_bed as index_bed_tpm {
    input:
      bed=normalize_counts.bed_tpm, 
  }

  call normalize.index_bed as index_bed_int {
    input:
      bed=normalize_counts.bed_int, 
  }

  call copy2bucket.CopyFiles2Directory as copy_2 {
    input: 
      files_2_copy=[normalize_counts.parquet_tpm, normalize_counts.bed_tpm, normalize_counts.parquet_int, normalize_counts.bed_int, index_bed_tpm.bed_gz, index_bed_tpm.bed_tbi, index_bed_int.bed_gz, index_bed_int.bed_tbi],
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

}
