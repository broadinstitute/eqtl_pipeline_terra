version 1.0

# import other WDLs
import "../tasks/run_tensorqtl_cis_permutations.wdl" as run_tensorqtl_cis_permutations
import "../tasks/copy_to_google_bucket.wdl" as copy2bucket

workflow tensorqtl_cis_permutations_peers_workflow {
  input {
    Array[File] covariates_files

    File plink_bed
    File plink_bim
    File plink_fam

    File phenotype_bed

    String output_gs_dir
    String dir_name = ""
  }

  scatter(file in covariates_files) {
    call run_tensorqtl_cis_permutations.tensorqtl_cis_permutations {
      input: 
        covariates=file, 
        plink_bed=plink_bed, 
        plink_bim=plink_bim, 
        plink_fam=plink_fam, 
        phenotype_bed=phenotype_bed, 
    }
  }

  call copy2bucket.CopyFiles2Directory as copy_1 {
    input: 
      files_2_copy=tensorqtl_cis_permutations.cis_qtl,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

}
