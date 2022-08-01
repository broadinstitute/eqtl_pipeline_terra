import "https://api.firecloud.org/ga4gh/v1/tools/scRNA_eQTL_pipeline_v1:run_peer/versions/10/plain-WDL/descriptor" as peers
import "https://api.firecloud.org/ga4gh/v1/tools/scRNA_eQTL_pipeline_v1:run_tensorqtl_cis_permutations/versions/5/plain-WDL/descriptor" as qtl_mapping

workflow qtl_pipeline {

  call peers.eqtl_peer_factors_workflow 
  call qtl_mapping.tensorqtl_cis_permutations_peers_workflow

}
