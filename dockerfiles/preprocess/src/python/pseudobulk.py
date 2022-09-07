import argparse
import anndata
import numpy as np
import pandas as pd

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(dest="group_name", type=str,
                        help="group/village name")
    parser.add_argument("-s", "--sample_ids", dest="sample_ids", nargs='+', default=[], required=True,
                        help="samples to look in for cells belonging to the group/village")
    parser.add_argument("-d", "--cell_donor_maps", dest="cell_donor_maps", nargs='+', default=[], required=True,
                        help="cell donor maps to look in for cells belonging to the group/village")
    parser.add_argument("-g", "--cell_group_maps", dest="cell_group_maps", nargs='+', default=[], required=True,
                        help="cell group maps to look in for cells belonging to the group/village")
    parser.add_argument("-c", "--counts", dest="h5ads", nargs='+', default=[], required=True,
                        help="count matrices (h5ads) to look in for cells belonging to the group/village")
    args = parser.parse_args()

    c_d_map_list = []
    counts_list = []

    for sample_id in args.sample_ids:                                        

        # read in cell to group assignment 
        filename = [s for s in args.cell_group_maps if sample_id in s][0]
        cell_group_df = pd.read_csv(filename, sep='\t')
        cell_group_df.columns = ['CBC', 'group_name']
        
        # get the cells that are assigned to this group_name / village
        cell_group_df = cell_group_df.query('group_name==@args.group_name')
        
        # get the cell to donor_map 
        filename = [s for s in args.cell_donor_maps if sample_id in s][0]
        cell_donor_df = pd.read_csv(filename, sep='\t')
        cell_donor_df.columns = ['cell', 'bestSample']

        # get the cells that are assigned to this group_name / village
        cell_donor_df = cell_donor_df.query('cell.isin(@cell_group_df.CBC)')
        
        # load counts 
        filename = [s for s in args.h5ads if sample_id in s][0]
        counts = anndata.read_h5ad(filename)

        # get the cells that are assigned to this group_name / village
        obs = counts.obs[counts.obs.index.isin(cell_group_df['CBC'])] # obs = cells
        obs['sample'] = sample_id # annotate cells by the sample run
        counts.var_names_make_unique()
        X = counts.X[counts.obs.index.isin(cell_group_df['CBC']), :]
        
        # new counts matrix
        counts_new = anndata.AnnData(X=X, obs=obs, var=counts.var)

        # Append to lists
        c_d_map_list.append(cell_donor_df)
        counts_list.append(counts_new)

    # write out combined cell donor map
    cell_donor_map_comb = pd.concat(c_d_map_list)
    cell_donor_map_comb.to_csv(f'{args.group_name}_cell_to_donor.txt', sep='\t', index=False)

    # write out the combined count matrix
    counts_comb = anndata.concat(counts_list)
    counts_comb.var = counts.var # assuming that all the sample runs have matching var / genes
    counts_comb.write(f'{args.group_name}_counts.h5ad')