import pandas as pd
import argparse
import os

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("qtl_finemap", type=str,
                        help="qtl finemapping results")
    parser.add_argument("outfile", type=str)
    parser.add_argument("-c", dest="cis_nominal_results", nargs='+', default=[],
                        help="Array of strings (filenames) of cis-nominal results")
    args = parser.parse_args()

    finemapped_results = pd.read_parquet(args.qtl_finemap)

    merged_finemap_nominal = {}
    print(args.cis_nominal_results)
    for i, cis_nominal_fname in enumerate(args.cis_nominal_results):
        print(cis_nominal_fname)
        cis_nom = pd.read_parquet(cis_nominal_fname)
        merged_finemap_nominal[i] = finemapped_results.merge(cis_nom, on=['phenotype_id', 'variant_id', 'af'])

    pd.concat(merged_finemap_nominal).to_csv(args.outfile, sep='\t', index=False)

if __name__ == "__main__":
    main()
