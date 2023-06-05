version 1.0

# import other WDLs
import "tasks/pseudobulk.wdl" as pseudobulk
import "tasks/filter_cells_donors.wdl" as filter
import "tasks/normalize_counts.wdl" as normalize
import "tasks/filter_plink.wdl" as filter_plink
import "tasks/run_tensorqtl_cis_nominal.wdl" as run_tensorqtl_cis_nominal

# This workflow takes pseudobulked data and maps eQTLs
workflow village_qtls {
  input {

    String group_name # ex. ips_D0
    Array[String] sample_ids # ex. ips_D0
    Array[File] cell_donor_map # ex. '${sample_id}_cell_to_donor.txt'
    Array[File] cell_group_map # ex. ${sample_id}_cell_to_group.txt'
    Array[File] h5ad # ex. '${sample_id}_singlets_cbc_suffix.h5ad'

    File genes_to_keep
    File variants_to_keep
    File gene_gtf

    File covariates

    File plink_bed
    File plink_bim
    File plink_fam
  }

  # Pseudobulk the group
  call pseudobulk.pseudobulk as run_pseudobulk {
    input:
      group_name=group_name,
      sample_ids=sample_ids,
      cell_donor_map=cell_donor_map,
      cell_group_map=cell_group_map,
      h5ad=h5ad,
  }

  # Filter donors, genes, cells (and downscale large cells) 
  call filter.filter as filter_cells_donors {
    input:
      counts=run_pseudobulk.counts, 
      cell_donor_map=run_pseudobulk.cell_donor_map_group,
      gene_gtf=gene_gtf,
      prefix=group_name,
      gene_list=genes_to_keep
  }

  # Normalize (TPM and Inverse Normal Transform)
  # TODO combine the indexing step
  call normalize.normalize as normalize_counts {
    input:
      counts_filtered=filter_cells_donors.counts_filtered, 
      prefix=group_name,
  }

  call normalize.index_bed as index_bed_tpm {
    input:
      bed=normalize_counts.bed_tpm, 
  }

  call normalize.index_bed as index_bed_int {
    input:
      bed=normalize_counts.bed_int, 
  }

  call filter_plink.filter_plink as filter_plink {
    input:
      plink_bed=plink_bed,
      plink_fam=plink_fam,
      plink_bim=plink_bim,
      variants_to_keep=variants_to_keep
  }
  
  # Run tensorQTL cis nominal scan for significant cis-eQTLs
  call run_tensorqtl_cis_nominal.tensorqtl_cis_nominal as cis_nominal {
    input: 
      plink_bed=filter_plink.bed, 
      plink_bim=filter_plink.bim, 
      plink_fam=filter_plink.fam,
      phenotype_bed=index_bed_int.bed_gz, 
      covariates=covariates, 
      prefix=group_name,
  }

  output {
    Array[File] qtl_nominal=cis_nominal.chr_parquet
  }

}
