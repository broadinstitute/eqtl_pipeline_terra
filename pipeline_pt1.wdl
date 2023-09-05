version 1.0

# import other WDLs
import "tasks/cbc_modify.wdl" as cbc_modify
import "https://raw.githubusercontent.com/broadinstitute/ParallelDonorAssignment/dropulation_likelihoods/donor_assignment/donor_assignment.wdl" as donorassign


# This workflow takes cellranger data to grouped pseudobulk
workflow scEQTL_pseudobulk {
  input {
    # 10x sample name - will produce one cellxgene count per sample
    String sample_id

    # village name (ips_D0)
    String group_name
    # cellranger inputs - multiple 10x runs per sample
    String cellranger_directory

    # VCF and gene info

    # Donor genotypes - should be prefiltered for HWE>=1e-7, MAF>=0.01, R2>=0.6
    File VCF
    # tabix index for VCF
    File VCF_TBI

    # BAM file
    File annotatedbam
    # Thresholds
    Float singlet_threshold = 0.75  # in doublet assignment

    # # Donor Assignment arguments
    File BAI
    Int num_splits
    # which donors from VCF to include
    File donor_list_file
    File whitelist
    String likelihood_method
    String docker_image = 'us.gcr.io/landerlab-atacseq-200218/donor_assign:0.20'
    String git_branch = "dropulation_likelihoods"
  }

  # Task calls
 
  # add slash if needed
  String cellranger_path = sub(cellranger_directory, "[/\\s]+$", "") + "/"

  
  # CBC file from cellranger output directory
  File cbc_barcodes = cellranger_path + "raw_feature_bc_matrix/barcodes.tsv.gz"

  call donorassign.donor_assign as donorassignment {
    input:
    BAI=BAI,
    BAM=annotatedbam,
    num_splits=num_splits,
    VCF=VCF,
    donor_list_file=donor_list_file,
    whitelist=whitelist,
    likelihood_method=likelihood_method,
    docker_image=docker_image,
    git_branch=git_branch
  }

  # Modify CBCs
  call cbc_modify.cbc_modify as run_cbc_modify {
    input:
    sample_id=sample_id, 
    group_name=group_name, 
    h5=cellranger_path + "raw_feature_bc_matrix.h5",
    cell_donor_assignments=donorassignment.singlets, 
  }

  output {
    File cell_donor_assignments=run_cbc_modify.renamed_cell_donor_assingments
    File h5ad=run_cbc_modify.h5ad_renamed
  }

}
