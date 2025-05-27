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

    print("READING IN FINEMAPPED RESULTS")
    finemapped_results = pd.read_parquet(args.qtl_finemap)
    print("DONE: READING IN FINEMAPPED RESULTS")
    merged_finemap_nominal = {}

    print('PRINTING args.cis_nominal_results')
    print(args.cis_nominal_results)

    print("READING IN CIS NOMINAL RESULTS")
    for i, cis_nominal_fname in enumerate(args.cis_nominal_results):
        print('PRINTING cis_nominal_fname:')
        print(cis_nominal_fname)
        cis_nom = pd.read_parquet(cis_nominal_fname)
        merged_finemap_nominal[i] = finemapped_results.merge(cis_nom, on=['phenotype_id', 'variant_id', 'af'])
    print("DONE: READING IN CIS NOMINAL RESULTS. NEXT, CONCATENATE")

    pd.concat(merged_finemap_nominal).to_parquet(args.outfile)
    print("DONE: CONCATENATE MERGED FINEMAP NOMINAL")

if __name__ == "__main__":
    main()
