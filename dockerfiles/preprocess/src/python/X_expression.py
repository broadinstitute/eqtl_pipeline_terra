import pandas as pd
import pylab
import argparse
import seaborn as sns
import matplotlib.pyplot as plt

params = {
    "legend.fontsize": "40",
    "figure.figsize": (10, 10),
    "axes.labelsize": "40",
    "axes.titlesize": "50",
    "xtick.labelsize": "40",
    "ytick.labelsize": "40",
    "axes.linewidth": "0.5",
    "pdf.fonttype": "42",
    "font.sans-serif": "Helvetica",
}
pylab.rcParams.update(params)

def main():
    parser = argparse.ArgumentParser(
            description="Add X expression covariate & generate QC plots."
        )
    parser.add_argument("parquet_tpm", type=str)
    parser.add_argument("covariates", type=str)
    parser.add_argument("outfile", type=str)
    args = parser.parse_args()

    # donor expression in TPM
    expression_tpm = pd.read_parquet(args.parquet_tpm)
    print("Getting X Expression")
    # get normalized donor expression in chrom X only
    Xchrom_expression = expression_tpm[expression_tpm['#chr'] == 'chrX'].iloc[:, 4:]
    Xchrom_expression_sum = Xchrom_expression.sum()
    norm_X_expr = (Xchrom_expression_sum - Xchrom_expression_sum.mean()) / Xchrom_expression_sum.std()

    # get PEER selection output table (covariates)
    peer_selection_output = pd.read_table(args.covariates, index_col=0)

    # Add X expression for all donors, and females only as covariates
    peer_selection_output.loc['norm_X_expression'] = norm_X_expr
    peer_selection_output.loc['norm_X_females'] = peer_selection_output.apply(lambda x: x.norm_X_expression if x.sex == 0 else 0)

    # overwrite covs
    print("saving csv")
    peer_selection_output.reset_index().to_csv(args.outfile, sep='\t', index=False)

    # generate QC plots
    print("Generating QC plots")
    X_expression_df = pd.concat([norm_X_expr.rename('Norm X Expression'), peer_selection_output.loc['sex'].replace({0:"Female", 1:"Male"})], axis=1)

    # X expression density plot
    fig, ax = plt.subplots(figsize=(9, 7), tight_layout=True)
    ax.hist(X_expression_df.query('sex=="Male"')['Norm X Expression'], density=True, bins=30, label='Male');
    ax.hist(X_expression_df.query('sex=="Female"')['Norm X Expression'], density=True, bins=30, label='Female');
    ax.legend(fontsize=25)
    ax.set_xlabel('Normalized X Expression')
    ax.set_ylabel('Density')
    plt.savefig("X_expression_density_plot.png")

    # XIST Expression plot
    if Xchrom_expression.index.str.contains('XIST').any():
        fig, ax = plt.subplots(figsize=(9, 7), tight_layout=True)
        XIST_df = pd.concat([Xchrom_expression.loc['XIST'], X_expression_df], axis=1)
        sns.scatterplot(x='XIST', y='Norm X Expression', hue='sex', data=XIST_df.sort_values('sex'), ax=ax)
        ax.legend(title='Sex', fontsize=25, title_fontsize=30)
        ax.set_xlabel("XIST gene expression")
        ax.set_ylabel("Normalized total\n X chr expression")
        plt.savefig("XIST_expression_plot.png", dpi=200)


if __name__ == "__main__":
    main()