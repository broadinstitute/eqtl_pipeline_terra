version 1.0

# import other WDLs
import "../tasks/run_tensorqtl_cis_nominal.wdl" as run_tensorqtl_cis_nominal
import "../tasks/copy_to_google_bucket.wdl" as copy2bucket

workflow tensorqtl_cis_nominal_workflow {
  input {
    File plink_bed
    File plink_bim
    File plink_fam

    File phenotype_bed
    File covariates
    String prefix

    String output_gs_dir
    String dir_name = ""
  }

  call run_tensorqtl_cis_nominal.tensorqtl_cis_nominal {
    input: 
      plink_bed=plink_bed, 
      plink_bim=plink_bim, 
      plink_fam=plink_fam,
      prefix=prefix, 
      phenotype_bed=phenotype_bed, 
      covariates=covariates, 

  }

  call copy2bucket.CopyFiles2Directory as copy_1 {
    input: 
      files_2_copy=tensorqtl_cis_nominal.chr_parquet,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

}
