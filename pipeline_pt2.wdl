version 1.0

# import other WDLs
import "tasks/pseudobulk.wdl" as pseudobulk
import "tasks/qc_plots.wdl" as qc
import "tasks/filter_cells_donors.wdl" as filter
import "tasks/normalize_counts.wdl" as normalize
import "tasks/run_peer.wdl" as run_peer
import "tasks/run_tensorqtl_cis_permutations.wdl" as run_tensorqtl_cis_permutations
import "tasks/peer_selection.wdl" as peer_selection
import "tasks/run_tensorqtl_cis_nominal.wdl" as run_tensorqtl_cis_nominal
import "tasks/run_tensorqtl_susie.wdl" as run_tensorqtl_susie
import "tasks/run_tensorqtl_trans.wdl" as run_tensorqtl_trans
import "tasks/X_expression.wdl" as X_expression
import "tasks/merge_cis_nominal_finemap.wdl" as merge_cis_nominal_finemap

# This workflow takes pseudobulked data and maps eQTLs
workflow village_qtls {
  input {

    String group_name # ex. ips_D0
    File normalized_bed  # INT-transformed .tsv (genes x donors), with columns chr TSS_start TSS_end Gene donor1 donor2...
    Array[Int] peer_range
    Int n_all_peers # TODO make n_all_peers max(peer_range)
    Int n_chosen_peers=5

    File plink_bed
    File plink_bim
    File plink_fam
  }

  call normalize.index_bed as index_bed_int {
    input:
      bed=normalized_bed
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
    call run_tensorqtl_cis_permutations.tensorqtl_cis_permutations as cis_permutations {
      input:
        covariates=file,
        plink_bed=plink_bed,
        plink_bim=plink_bim,
        plink_fam=plink_fam,
        phenotype_bed=index_bed_int.bed_gz,
    }
  }

  # Plot eQTL discovery curve for the PEER range (option to manually choose # PEERs to correct with)
  call peer_selection.peer_selection as run_peer_selection {
    input:
      cis_eqtl_results=cis_permutations.cis_qtl,
      covariates=subset_peers_and_combine.combined_covariates,
      n_chosen_peers=n_chosen_peers,
      prefix=group_name,
  }

#   call X_expression.add_X_covariates as add_X_covariates {
#     input:
#       covariates=run_peer_selection.chosen_peer_covariates,
#       parquet_tpm=normalize_counts.parquet_tpm,
#   }
# 
  # Run tensorQTL cis nominal scan for significant cis-eQTLs
  call run_tensorqtl_cis_nominal.tensorqtl_cis_nominal as cis_nominal {
    input:
      plink_bed=plink_bed,
      plink_bim=plink_bim,
      plink_fam=plink_fam,
      phenotype_bed=index_bed_int.bed_gz,
      covariates=run_peer_selection.chosen_peer_covariates,
      prefix=group_name,
  }

  # Run tensorQTL SuSiE fine-mapping scan for significant cis-eQTLs
  call run_tensorqtl_susie.tensorqtl_cis_susie as cis_susie {
    input:
      plink_bed=plink_bed,
      plink_bim=plink_bim,
      plink_fam=plink_fam,
      phenotype_bed=index_bed_int.bed_gz,
      covariates=run_peer_selection.chosen_peer_covariates,
      prefix=group_name,
      cis_output=run_peer_selection.chosen_peer_qtls,
  }

  # merge SuSiE fine-mapping and cis-nominals
  call merge_cis_nominal_finemap.merge_cis_nominal_with_finemap as merge_results {
    input:
      qtl_nominal=cis_nominal.chr_parquet,
      qtl_finemap=cis_susie.parquet
  }

  # Run tensorQTL trans scan for significant trans-eQTLs
  call run_tensorqtl_trans.tensorqtl_trans as trans_qtls {
    input:
      plink_bed=plink_bed,
      plink_bim=plink_bim,
      plink_fam=plink_fam,
      phenotype_bed=index_bed_int.bed_gz,
      covariates=run_peer_selection.chosen_peer_covariates,
      prefix=group_name,
  }

  output {
    # plots
#    File umi_cell_png=qc_plots.umi_cell_png
#    File gene_cell_png=qc_plots.gene_cell_png
#    File cell_donor_png=qc_plots.cell_donor_png
    File peer_png=run_peer_selection.peer_png
#    File XIST_expression_png=add_X_covariates.XIST_expression_plot
#    File X_expression_density_png=add_X_covariates.density_X_expression_plot

    # count matrices and covariates
#    File counts_tpm=normalize_counts.parquet_tpm
#    File counts_int=normalize_counts.parquet_int
    File final_covariates=run_peer_selection.chosen_peer_covariates

    # qtl results
    File qtl_perm=run_peer_selection.chosen_peer_qtls
    Array[File] qtl_nominal=cis_nominal.chr_parquet
    File qtl_finemap=merge_results.parquet
    Array[File] qtl_trans=trans_qtls.chr_parquet
  }

}
