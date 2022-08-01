version 1.0 
## Copyright Broad Institute, 2020
##
## LICENSING :
## This script is released under the WDL source code license (BSD-3)
## (see LICENSE in https://github.com/openwdl/wdl).

workflow cellbender_remove_background {
  call run_cellbender_remove_background_gpu
}

task run_cellbender_remove_background_gpu {
  input {
    # File-related inputs
    String sample_name
    File input_10x_h5_file_or_mtx_directory

    # Docker image for cellbender remove-background version
    String docker_image = "us.gcr.io/broad-dsde-methods/cellbender@sha256:de3b40518d634b42a262a9dadf556092e1e0186016f161bad1c17098ec72d87f"

    # Method configuration inputs
    Int? expected_cells
    Int? total_droplets_included
    Float? fpr  # must be 1 value (not an array of values)
    String? model
    Int? low_count_threshold
    Int? epochs
    Int? z_dim
    String? z_layers  # in quotes: integers separated by whitespace
    Float? empty_drop_training_fraction
    String? blacklist_genes  # in quotes: integers separated by whitespace
    Float? learning_rate
    Boolean exclude_antibody_capture = false

    # Hardware-related inputs
    String hardware_zones = "us-east1-d us-east1-c us-central1-a us-central1-c us-west1-b"
    Int hardware_disk_size_GB = 50
    Int hardware_boot_disk_size_GB = 20
    Int hardware_preemptible_tries = 0
    Int hardware_cpu_count = 4
    Int hardware_memory_GB = 15
    String hardware_gpu_type = "nvidia-tesla-t4"

  }


  command {
    cellbender remove-background \
      --input "${input_10x_h5_file_or_mtx_directory}" \
      --output "${sample_name}_out.h5" \
      --cuda \
      ${"--expected-cells " + expected_cells} \
      ${"--total-droplets-included " + total_droplets_included} \
      ${"--fpr " + fpr} \
      ${"--model " + model} \
      ${"--low-count-threshold " + low_count_threshold} \
      ${"--epochs " + epochs} \
      ${"--z-dim " + z_dim} \
      ${"--z-layers " + z_layers} \
      ${"--empty-drop-training-fraction " + empty_drop_training_fraction} \
      ${"--blacklist-genes " + blacklist_genes} \
      ${"--learning-rate " + learning_rate} \
      ${true="--exclude-antibody-capture" false=" " exclude_antibody_capture}

  }

  output {
    File log = "${sample_name}_out.log"
    File pdf = "${sample_name}_out.pdf"
    File csv = "${sample_name}_out_cell_barcodes.csv"
    File h5_array = "${sample_name}_out.h5" 
  }

  runtime {
    docker: "${docker_image}"
    bootDiskSizeGb: hardware_boot_disk_size_GB
    disks: "local-disk ${hardware_disk_size_GB} HDD"
    memory: "${hardware_memory_GB}G"
    cpu: hardware_cpu_count
    zones: "${hardware_zones}"
    gpuCount: 1
    gpuType: "${hardware_gpu_type}"
    preemptible: hardware_preemptible_tries
    maxRetries: 0
  }

}


