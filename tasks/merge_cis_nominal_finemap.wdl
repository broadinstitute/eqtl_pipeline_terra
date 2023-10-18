version 1.0

task merge_cis_nominal_with_finemap{
    input {
        Array[String] qtl_nominal
        File qtl_finemap
    }

    String outfile = basename(qtl_finemap, ".parquet") + "_with_cis_nom.parquet"

    command {
        set -euo pipefail
        python /merge_cis_nominal_finemap.py ${qtl_finemap} ${outfile} -c ${sep=' ' qtl_nominal}
    }

    output {
        File parquet=outfile
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:0.4"
    }
}