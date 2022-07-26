version 1.0

# import other WDLs
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:dropseqannotatebam/versions/3/plain-WDL/descriptor" as annotate
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:DropulationAssignCellsToDonors/versions/10/plain-WDL/descriptor" as donorassign
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:DropulationDetectDoublets_maxerr/versions/2/plain-WDL/descriptor" as detectdoublets
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:remove-doublets/versions/3/plain-WDL/descriptor" as removedoublets
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:run_cellbender/versions/5/plain-WDL/descriptor" as cellbender


# This workflow takes cellranger data to grouped pseudobulk
workflow scEQTL_pseudobulk {
  input {
    # sample name - will produce one cellxgene count per sample
    String sample_id
    # String scratch_dir # TODO

    # cellranger inputs - multiple 10x runs per sample
    String cellranger_directory

    # VCF and gene info

    # Donor genotypes - should be prefiltered for HWE>=1e-7, MAF>=0.01, R2>=0.6
    File VCF
    # tabix index for VCF
    File VCF_TBI
    # gene annotation file
    File GTF

    # Donor information
    
    # which donors from VCF to include
    File donors_to_include

    # Cell to group/cluster map

    # 10x-sample+CBC as index, mapping to subgroup or cluster
    # File cell_to_group # TODO

    # Explicit covariates to add to pseudobulk groups

    # per-donor covariates - tab separated pandas, VCF ID as index
    # File donor_covariates # TODO
    # per-10x-channel covariates - tsv, 10x-sample ID as index
    # File sample_covariates # TODO

    # Thresholds
    Float min_maf = 0.05  # for donors, PCA, tensorqtl
    Float singlet_threshold = 0.79  # in doublet assignment
    Int minimum_umis_per_cell = 2000

    # Cellbender arguments
    Int cellbender_total_droplets
    Int cellbender_expected_cells
    Float? cellbender_fpr = 0.01
  }

  # Task calls
 
  # add slash if needed
  String cellranger_path = sub(cellranger_directory, "[/\\s]+$", "") + "/"

  # Annotate bam for double detection
  call annotate.annotatecellranger as annotation {
    input:
    bam=cellranger_path + 'possorted_genome_bam.bam',
    gtf=GTF
  }

  # CBC file from cellranger output directory
  File cbc_barcodes = cellranger_path + "filtered_feature_bc_matrix/barcodes.tsv.gz"
  call donorassign.donorassign as donorassignment {
    input:
    bam=annotation.annotatedbam,
    whitelist=cbc_barcodes,
    VCF=VCF,
    TBI=VCF_TBI,
    sample_names=donors_to_include,
    outname=sample_id
  }
  
  # Doublet detection
  call detectdoublets.detectdoublets as doublets {
    input:
    likelihood_file=donorassignment.assignments,
    whitelist=cbc_barcodes,
    bam=annotation.annotatedbam,
    VCF=donorassignment.outvcf,
    sample_names=donors_to_include,
    outname=sample_id
  }

  # Remove doublets
  call removedoublets.remove_doublets as doublet_removal {
    input:
    h5=cellranger_path + "raw_feature_bc_matrix.h5",
    doublets=doublets.doublets,
    threshold=singlet_threshold
  }

  # Remove background with cellbender 
  call cellbender.run_cellbender_remove_background_gpu as run_cellbender {
    input:
    input_10x_h5_file_or_mtx_directory=doublet_removal.h5ad_filtered,
    sample_name=sample_id,
    expected_cells=cellbender_expected_cells,
    fpr=cellbender_fpr,
    total_droplets_included=cellbender_total_droplets
  }

  # Filter to singlets 
  call removedoublets.filter_to_singlets as singlet_filter {
    input:
    h5=run_cellbender.h5_array,
    doublets=doublets.doublets,
    threshold=singlet_threshold
  }

}
