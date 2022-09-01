import argparse
import anndata
import numpy as np
import pandas as pd

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(dest="counts", type=str,
                        help="H5AD file of counts")
    parser.add_argument(dest="donormap", type=str,
                        help="cell to donor assignments")
    parser.add_argument(dest="sample_id", type=str,
                        help="sample name")
    parser.add_argument(dest="group_name", type=str,
                        help="group/village name")
    args = parser.parse_args()

    # load counts
    counts = anndata.read_h5ad(args.counts)

    # Filter and output the cell_to_donor map with new CBC
    cell_to_donor_map = pd.read_csv(args.donormap, 
              sep='\t', skiprows=1, usecols=['cell', 'bestSample'])

    # Filter cell donor map to match the counts matrix (singlets only)
    cell_to_donor_out = cell_to_donor_map.query('cell.isin(@counts.obs.index)')

    # Modify CBC with suffix
    cell_to_donor_out['cell'] += f'-{args.sample_id}'
    cell_to_donor_out.to_csv(f'{args.sample_id}_cell_to_donor.txt', sep='\t', index=False)

    # write out the cell to village group mapping
    cell_to_group_out = cell_to_donor_out.set_axis(['cell', 'group_name'], axis=1)
    cell_to_group_out['group_name'] = args.group_name
    cell_to_group_out.to_csv(f'{args.sample_id}_cell_to_group.txt', sep='\t', index=False)

    # update CBC in counts matrix with suffix
    counts.obs.index += f'-{args.sample_id}'
    counts.write(f'{args.sample_id}_singlets_cbc_suffix.h5ad')