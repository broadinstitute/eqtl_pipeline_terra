version 1.0

# import other WDLs
import "tasks/pseudobulk.wdl" as pseudobulk
import "tasks/qc_plots.wdl" as qc
import "tasks/filter_cells_donors.wdl" as filter
import "tasks/normalize_counts.wdl" as normalize
import "tasks/run_peer.wdl" as run_peer
import "tasks/run_tensorqtl_cis_permutations.wdl" as run_tensorqtl_cis_permutations

# This workflow takes pseudobulked data and maps eQTLs
workflow village_qtls {
  input {
    # File counts
    # File cell_donor_map

    String group_name # ex. ips_D0
    Array[String] sample_ids # ex. ips_D0
    Array[File] cell_donor_map # ex. '${sample_id}_cell_to_donor.txt'
    Array[File] cell_group_map # ex. ${sample_id}_cell_to_group.txt'
    Array[File] h5ad # ex. '${sample_id}_singlets_cbc_suffix.h5ad'

    File gene_gtf
    # String prefix

    Array[Int] peer_range
    Int n_all_peers
    Int n_chosen_peers=5

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

  # Make QC plots for UMIs/cell, genes/cell, cells/donor
  call qc.qc_plots as qc_plots {
    input:
      counts=run_pseudobulk.counts, 
      cell_donor_map=run_pseudobulk.cell_donor_map_group,
      prefix=group_name,
  }

  # Filter donors, genes, cells (and downscale large cells) 
  call filter.filter as filter_cells_donors {
    input:
      counts=run_pseudobulk.counts, 
      cell_donor_map=run_pseudobulk.cell_donor_map_group,
      gene_gtf=gene_gtf,
      prefix=group_name,
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

  # Run PEER with the max number of factors in the range
  call run_peer.all_peer_factors as all_peer_factors {
    input:
      expression_file=index_bed_int.bed_gz,
      n_all_peers=n_all_peers, 
      prefix=group_name,
  }

  # Subset for the PEERs to test 
  scatter (n_peer in peer_range) {
    call run_peer.subset_peers_and_combine as subset_peers_and_combine {
      input:
        n_peer=n_peer,
        peer_covariates=all_peer_factors.peer_covariates, 
        prefix=group_name,
    }
  }

  # Run tensorQTL cis permutations for each number of PEER correction
  scatter(file in subset_peers_and_combine.combined_covariates) {
    call run_tensorqtl_cis_permutations.tensorqtl_cis_permutations {
      input: 
        covariates=file, 
        plink_bed=plink_bed, 
        plink_bim=plink_bim, 
        plink_fam=plink_fam, 
        phenotype_bed=index_bed_int.bed_gz, 
    }
  }

  # Plot eQTL discovery curve for the PEER range (option to manually choose # PEERs to correct with)

  # Run tensorQTL cis nominal scan for significant cis-eQTLs

  # Run tensorQTL SuSiE fine-mapping scan for significant cis-eQTLs
  
}