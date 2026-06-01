#!/usr/bin/env python3

from cyvcf2 import VCF
import pandas as pd
import numpy as np
import argparse
from pathlib import Path

def parse_cla():
    parser = argparse.ArgumentParser(
        description="Process HipSTR VCF file to create a matrix of mean STR lengths."
    )
    parser.add_argument(
        "-i", "--input-vcf",
        required=True,
        help="Path to the input HipSTR VCF file (can be gzipped)."
    )
    parser.add_argument(
        "-o", "--output-dir",
        required=True,
        help="Path for the output files."
    )
    parser.add_argument(
        "--min-var",
        type=float,
        default=0.1,
        help="Minimum variance of mean STR lengths to include a locus. Default: 0.1"
    )
    return parser.parse_args()

def mean_str_length(s):
    """
    Calculates the mean STR length for each sample from HipSTR's GB field.
    Handles multiple alleles '|' separated and missing data '.'.
    """
    f_list = np.array([
        np.mean(list(map(float, val.split('|')))) if val != "." else np.nan
            for val in s ], dtype=np.float32)
    return f_list

def df_from_vcf(vcf_file, min_var):
    vcf = VCF(vcf_file)
    str_info = []
    str_matrix = []
    for variant in vcf:
        if variant.INFO["PERIOD"] > 6:
           continue
        else:
           ref_len = round((variant.end - variant.start)/variant.INFO["PERIOD"])
           ncopy = mean_str_length(variant.format("GB")) + ref_len
           str_var = np.nanvar(ncopy)
           if str_var > min_var:
               str_matrix.append(ncopy)
               str_info.append({"start" : variant.start,
                        "end" : variant.end,
                        "period" : variant.INFO["PERIOD"],
                        "ref" : variant.REF,
                        "ref_len" : ref_len,
                        "str_var" : str_var})
    str_info = pd.DataFrame(str_info)
    str_matrix = pd.DataFrame(str_matrix)
    str_matrix.columns = np.array(vcf.samples)
    
    return str_info, str_matrix

def main():
    args = parse_cla()
    str_info, str_matrix = df_from_vcf(args.input_vcf, args.min_var)
    filename = Path(args.input_vcf).stem.split("_")[0]
    str_info.to_csv(args.output_dir + filename + "_info.csv")
    str_matrix.to_csv(args.output_dir + filename + "_hgdp.csv")

if __name__ == "__main__":
    main()


