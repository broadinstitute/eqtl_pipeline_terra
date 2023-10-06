version 1.0

task add_X_covariates{
    input {
        File covariates
        File parquet_tpm
    }

    command {
        set -euo pipefail

        python <<CODE
        import pandas as pd

        # donor expression in TPM
        expression_tpm = pd.read_parquet('${parquet_tpm}')

        # get normalized donor expression in chrom X only
        Xchrom_expression = expression_tpm[expression_tpm['#chr'] == 'chrX'].iloc[:, 4:]
        Xchrom_expression_sum = Xchrom_expression.sum()
        norm_X_expr = (Xchrom_expression_sum - Xchrom_expression_sum.mean()) / Xchrom_expression_sum.std()

        # get PEER selection output table (covariates)
        peer_selection_output = pd.read_table('${covariates}', index_col=0)

        # Add X expression for all donors, and females only as covariates
        peer_selection_output.loc['norm_X_expression'] = norm_X_expr
        peer_selection_output.loc['norm_X_females'] = peer_selection_output.apply(lambda x: x.norm_X_expression if x.sex == 0 else 0)

        # overwrite covs
        peer_selection_output.reset_index().to_csv('${covariates}', sep='\t', index=False)

        CODE
    }

    output {
        File chosen_peer_covariates="${covariates}"
    }

    runtime {
        docker: "us.gcr.io/landerlab-atacseq-200218/eqtl_preprocess:v8"
    }
}