version 1.0

# import other WDLs
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:dropseqannotatebam/versions/3/plain-WDL/descriptor" as annotate
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:DropulationAssignCellsToDonors/versions/10/plain-WDL/descriptor" as donorassign
# import "tasks/run_cellbender.wdl" as cellbender
import "tasks/cbc_modify.wdl" as cbc_modify


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
    # gene annotation file
    File GTF
    
    # which donors from VCF to include
    File donors_to_include

    # Thresholds
    Float singlet_threshold = 0.75  # in doublet assignment

    # # Cellbender arguments
    # Int cellbender_total_droplets
    # Int cellbender_expected_cells
    # Float? cellbender_fpr = 0.01
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

  # Modify CBCs
  call cbc_modify.cbc_modify as run_cbc_modify {
    input:
    sample_id=sample_id, 
    group_name=group_name, 
    h5=cellranger_path + "raw_feature_bc_matrix.h5",
    cell_donor_assignments=donorassignment.assignments, 
  }

  output {
    File cell_donor_map=run_cbc_modify.cell_donor_map
    File cell_group_map=run_cbc_modify.cell_group_map
    File h5ad=run_cbc_modify.h5ad_renamed
  }

}
