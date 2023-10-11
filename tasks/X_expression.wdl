version 1.0

task add_X_covariates{
    input {
        File covariates
        File parquet_tpm
        String prefix
    }

    command {
        set -euo pipefail
        pip install seaborn
        python /X_expression.py ${parquet_tpm} ${covariates}
    }

    output {
        File chosen_peer_covariates="${covariates}"
        File XIST_expression_plot="${prefix}_XIST_expression.png"
        File density_X_expression_plot="${prefix}_X_expression_density.png"
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8"
    }
}