version 1.0

# import other WDLs
import "tasks/variant-annotation/annotate_ldsc.wdl" as annotate_ldsc
# import "tasks/variant-annotation/remove_doublets.wdl" as annotate_peaks

# This workflow takes cellranger data to grouped pseudobulk
workflow scEQTL_pseudobulk {
  input {

    # variants to annotate
    File variant_file # ex. fine-mapping file
    File VCF

    # annotations
    # File ldsc
    # File abc
    # Array[File] peaks

  }

  # Task calls
  call annotate_ldsc.annotate_ldsc {
    input:
    variant_file=variant_file,
  }
}
