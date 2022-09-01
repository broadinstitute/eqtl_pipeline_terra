version 1.0
task qc_plots {
  input {
    File counts
    File cell_donor_map
    String prefix
    String docker_image='us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8'

    Int memory=32
    Int disk_space=32
    Int num_threads=4
    Int num_preempt=1
  }
