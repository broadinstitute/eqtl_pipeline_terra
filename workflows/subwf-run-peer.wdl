version 1.0

# import other WDLs
import "../tasks/run_peer.wdl" as run_peer
import "../tasks/copy_to_google_bucket.wdl" as copy2bucket

workflow eqtl_peer_factors_workflow {
  input {
    Array[Int] peer_range
    Int n_all_peers
    File expression_file

    String prefix

    String output_gs_dir
    String dir_name = ""
  }

  # Run PEER with the max number of factors in the range
  call run_peer.all_peer_factors {
    input:
      expression_file=expression_file,
      n_all_peers=n_all_peers, 
      prefix=prefix,
  }

  # TODO check if these copy commands can be collapsed into one
  call copy2bucket.CopyFiles2Directory as copy_1 {
    input: 
      files_2_copy=[all_peer_factors.peer_covariates],
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

  call copy2bucket.CopyFiles2Directory as copy_2 {
    input: 
      files_2_copy=[all_peer_factors.alpha],
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

  # Subset for the PEERs to test 
  scatter (n_peer in peer_range) {
    call run_peer.subset_peers_and_combine {
      input:
        n_peer=n_peer,
        peer_covariates=all_peer_factors.peer_covariates, 
        prefix=prefix,
    }
  }

  call copy2bucket.CopyFiles2Directory as copy_3 {
    input: 
      files_2_copy=subset_peers_and_combine.combined_covariates,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

}

