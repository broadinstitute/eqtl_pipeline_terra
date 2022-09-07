version 1.0

# import other WDLs
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:dropseqannotatebam/versions/3/plain-WDL/descriptor" as annotate
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:DropulationAssignCellsToDonors/versions/10/plain-WDL/descriptor" as donorassign
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:DropulationDetectDoublets_maxerr/versions/2/plain-WDL/descriptor" as detectdoublets
import "tasks/remove_doublets.wdl" as removedoublets
import "tasks/run_cellbender.wdl" as cellbender
import "tasks/cbc_modify.wdl" as cbc_modify


# This workflow takes cellranger data to grouped pseudobulk
workflow scEQTL_pseudobulk {
  input {
    # sample name - will produce one cellxgene count per sample
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
    # gene annotation file
    File GTF
    
    # which donors from VCF to include
    File donors_to_include

    # Thresholds
    Float singlet_threshold = 0.79  # in doublet assignment

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

  # modify CBC
  call cbc_modify.cbc_modify as run_cbc_modify {
    input:
    sample_id=sample_id, 
    group_name=group_name, 
    h5ad_filtered=singlet_filter.h5ad_filtered, 
    cell_donor_assignments=donorassignment.assignments, 
  }
}
