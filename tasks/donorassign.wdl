version 1.0

import "https://api.firecloud.org/ga4gh/v1/tools/landerlab:copy_to_google_bucket/versions/3/plain-WDL/descriptor" as copyfiles

workflow donorassignment {
  input {
    File cbc_whitelist_gz
    File bam
    File VCF
    File TBI
    File sample_names
    String output_name
    String dest_dir
  }

  call donorassign {
    input:
    whitelist=cbc_whitelist_gz,
    bam=bam,
    VCF=VCF,
    TBI=TBI,
    sample_names=sample_names,
    outname=output_name
  }

  call copyfiles.copyFile {
    input:
    files_2_copy = [donorassign.logfile, donorassign.assignments, donorassign.outvcf],
    output_gs_dir=dest_dir
  }
  
  output {
    File donorassign_logfile=donorassign.logfile
    File donorassign_result=donorassign.assignments
    File donorassign_vcf=donorassign.outvcf
  }
}

task donorassign {
  input {
    File whitelist
    File bam
    File VCF
    File TBI
    File sample_names
    String outname
  }

  Int runtime_disk_gb = ceil(size(bam, 'GB') + size(VCF, 'GB') + size(TBI, 'GB') + 10) * 3

  command {
  /software/monitor_script.sh &
  
  AssignCellsToSamples \
      -m40g \
      --CELL_BC_FILE <(gunzip -c ${whitelist}) \
      --CELL_BARCODE_TAG CB \
      --MOLECULAR_BARCODE_TAG UB \
      --INPUT_BAM ${bam} \
      --OUTPUT ${outname}_donor_assignments.txt \
      --VCF ${VCF} \
      --SAMPLE_FILE ${sample_names} \
      --GQ_THRESHOLD -1 \
      --LOCUS_FUNCTION_LIST INTRONIC \
      --VALIDATION_STRINGENCY LENIENT \
      --TMP_DIR ./tmp \
      --VCF_OUTPUT ${outname}_out.vcf > ${outname}_logfile.txt

  if [[ $(wc -l < ${outname}_donor_assignments.txt) -le 2 ]]
  then
      echo "No results!"
      rm ${outname}_donor_assignments.txt
  fi

  }

  output {
    File logfile=outname + '_logfile.txt'
    File assignments=outname + '_donor_assignments.txt'
    File outvcf=outname + '_out.vcf'
  }

  runtime {
    disks: 'local-disk ${runtime_disk_gb} HDD'
    cpu: '4'
    memory: '64 GB'
    docker: 'us.gcr.io/landerlab-atacseq-200218/landerlab-dropseq-2.5.0:1.0'
    preemptible: '3'
  }
}
