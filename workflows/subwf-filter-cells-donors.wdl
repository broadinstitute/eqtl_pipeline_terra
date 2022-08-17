version 1.0

# import other WDLs
import "../tasks/filter_cells_donors.wdl" as filter_cells_donors
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

  call filter_cells_donors.filter {
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

}


# workflow filter_workflow {

#     File counts
#     File cell_donor_map
#     Int? cell_per_donor_threshold
#     Int? umis_per_cell_threshold
#     File? donor_list
#     File? gene_list
#     File gene_gtf
#     String prefix

#     String output_gs_dir
#     String dir_name = ""

#     Int memory
#     Int disk_space
#     Int num_threads
#     Int num_preempt

#     call filter {
#         input:
#             counts=counts,
#             cell_donor_map=cell_donor_map,
#             cell_per_donor_threshold=cell_per_donor_threshold,
#             umis_per_cell_threshold=umis_per_cell_threshold,
#             donor_list=donor_list,
#             gene_list=gene_list,
#             gene_gtf=gene_gtf,
#             prefix=prefix,
#             memory=memory, 
#             disk_space=disk_space, 
#             num_threads=num_threads, 
#             num_preempt=num_preempt, 
#     }

#     call copy2bucket.CopyFiles2Directory as copy_1 {
#         input: 
#             files_2_copy=[filter.umi_cell_post_png, filter.counts_filtered],
#             output_gs_dir=output_gs_dir,
#             dir_name=dir_name,
#     }

#     call normalize {
#         input:
#             counts_filtered=filter.counts_filtered,
#             prefix=prefix,
#     }

#     call copy2bucket.CopyFiles2Directory as copy_2 {
#         input: 
#             files_2_copy=[normalize.parquet_tpm, normalize.bed_tpm, normalize.parquet_int, normalize.bed_int],
#             output_gs_dir=output_gs_dir,
#             dir_name=dir_name,
#     }

#     call index as index_tpm {
#         input:
#             bed=normalize.bed_tpm,
#     }

#     call index as index_int {
#         input:
#             bed=normalize.bed_int,
#     }

#     call copy2bucket.CopyFiles2Directory as copy_3 {
#         input: 
#             files_2_copy=[index_tpm.bed_gz, index_tpm.index, index_int.bed_gz, index_int.index],
#             output_gs_dir=output_gs_dir,
#             dir_name=dir_name,
#     }

# }