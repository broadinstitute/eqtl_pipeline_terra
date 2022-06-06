version 1.0

# import other WDLs
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:dropseqannotatebam/versions/3/plain-WDL/descriptor" as annotate
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:DropulationAssignCellsToDonors/versions/9/plain-WDL/descriptor" as donorassign
import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:DropulationDetectDoublets_maxerr/versions/1/plain-WDL/descriptor" as detectdoublets
import "https://api.firecloud.org/ga4gh/v1/tools/cellbender:remove-background/versions/11/plain-WDL/descriptor" as cellbender

# This workflow takes cellranger data to grouped pseudobulk
workflow scEQTL_pseudobulk {
  input {
    # sample name - will produce one cellxgene count per sample
    String sample_id
    String scratch_dir

    # cellranger inputs - multiple 10x runs per sample
    Array[String] cellranger_directories

    # VCF and gene info

    # Donor genotypes - should be prefiltered for HWE>=1e-7, MAF>=0.01, R2>=0.6
    File VCF
    # tabix index for VCF
    File VCF_TBI
    # gene annotation file
    File GTF

    # Donor information
    
    # which donors from VCF to include
    File? donors_to_include

    # Cell to group/cluster map

    # 10x-sample+CBC as index, mapping to subgroup or cluster
    File cell_to_group

    # Explicit covariates to add to pseudobulk groups

    # per-donor covariates - tab separated pandas, VCF ID as index
    File donor_covariates
    # per-10x-channel covariates - tsv, 10x-sample ID as index
    File sample_covariates

    # Thresholds
    Float? min_maf = 0.05  # for donors, PCA, tensorqtl
    Float? singlet_threshold = 0.79  # in doublet assignment
    Int? minimum_umis_per_cell = 2000

    # Cellbender arguments
    Int cellbender_total_droplets
    Int cellbender_expected_cells
    Float? cellbender_fpr = 0.01
  }

  # Task calls

  scatter (cellranger_path_raw in cellranger_directories) {
    # add slash if needed
    String cellranger_path = sub(cellranger_path_raw, "[/\\s]+$", "") + "/"

    # Annotate bam for double detection
    call annotate.annotatecellranger as annotation {
         input:
            bam=cellranger_path + '/possorted_genome_bam.bam',
            gtf=GTF
    }

    File cbc_barcodes = cellranger_path + "filtered_feature_bc_matrix/barcodes.tsv.gz"
    call donorassign.donorassign as donorassignment {
         input:
                bam=annotation.annotatedbam,
                whitelist=cbc_barcodes,
                VCF=VCF,
                TBI=TBI,
                sample_names=donors_to_include,
                outname=sample_id
         }
               
    call detectdoublets.detectdoublets as doublets {
         input:
                likelihood_file=donorassignment.assignments,
                whitelist=cbc_barcodes,
                bam=annotation.annotatedbam,
                VCF=VCF,
                sample_names=donors_to_include,
                outname=sample_id
         }

    # Filter to singlets
    call singlet_filter.filter as singlets {
         input:
                h5="",
                doublets=doublets.doublets,
                threshold=singlet_threshold
        }

    # cellbender - TODO - be a task, fpr not a string
    call cellbender.run_cellbender_remove_background_gpu as cellbender {
         input:
                input_10x_h5_file_or_mtx_directory=singlets.h5file,
                output_directory=scratch_dir,
                sample_name=sample_id,
                expected_cells=cellbender_expected_cells,
                fpr=String(cellbender_fpr),
                total_droplets_included=cellbender_total_droplets
         }

     # filter UMIs, downscale large cells, psuedobulk to donors

     }  # end of the scatter

  # sum up and TPM transform all h5s from last step in scatter
  }
