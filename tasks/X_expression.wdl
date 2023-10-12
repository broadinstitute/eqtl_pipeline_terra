version 1.0

task add_X_covariates{
    input {
        File covariates
        File parquet_tpm
    }

    String outfile = "with_X_" + basename(covariates)

    command {
        set -euo pipefail
        python /X_expression.py ${parquet_tpm} ${covariates} ${outfile}
    }

    output {
        File chosen_peer_covariates=outfile
        File XIST_expression_plot="XIST_expression_plot.png"
        File density_X_expression_plot="X_expression_density_plot.png"
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:0.3"
    }
}