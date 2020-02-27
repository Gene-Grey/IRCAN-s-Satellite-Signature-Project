"""
    Takes a .csv or .tsv Kmer-SSR output file and
    a txt metadata file as imputs and outputs a .json file
"""

import os
import sys
import json
from collections import OrderedDict

def hash_metadata(metadata_file):
    """
        Takes the .csv or .tsv Kmer-SSR output file
        and formats it in a python dictionnary;
        second part of the signature file
    """

    metadata = {}
    remarks = []

    for line in metadata_file:
        tab_split_line = line.strip('\n').split('\t')

        if len(tab_split_line) == 2:
            metadata[tab_split_line[0]] = tab_split_line[1]

        elif len(tab_split_line) == 3 and tab_split_line[0] == '':
            remarks.append(tab_split_line[2])

    metadata.update({"remarks": remarks})

    return metadata



def hash_kmerssr_output(kmerssr_output_file, has_header, formatting):
    """Recieves and checks both inputs, calls formatting funtions and outputs the .json file"""

    kmerssr_dict = {}

    if formatting == "csv":
        formatting_key = ','

    elif formatting == "tsv":
        formatting_key = "\t"

    for line in kmerssr_output_file:
        if has_header:
            has_header = False
            continue

        tab_split_line = line.strip('\n').split(formatting_key)
        ssr_key = tab_split_line[1]
        repeats_key = int(tab_split_line[2])

        try:
            kmerssr_dict[ssr_key]
        except KeyError:
            kmerssr_dict[ssr_key] = {}
            kmerssr_dict[ssr_key]["total"] = 0

        try:
            kmerssr_dict[ssr_key][repeats_key]
        except KeyError:
            kmerssr_dict[ssr_key][repeats_key] = 0

        kmerssr_dict[ssr_key][repeats_key] += 1
        kmerssr_dict[ssr_key]["total"] += 1

    ordered_list = sorted(kmerssr_dict, key=lambda x: kmerssr_dict[x]["total"])
    ssr_dict = {}

    for key in ordered_list:
        ssr_dict[key] = kmerssr_dict[key]

    return ssr_dict



def main():
    """Recieves and checks both inputs, calls formatting funtions and outputs the .json file"""

    signature_path = ""
    formatting = ""

    try:
        if (sys.argv[1].split(os.extsep)[-1] == 'txt' and
                sys.argv[1].split(os.extsep)[-2] == 'metadata'):
            metadata_content = list(open(sys.argv[1], "r"))
            satellite_content = list(open(sys.argv[2], "r"))
            signature_path = sys.argv[2].split(os.extsep)[-2]
            formatting = sys.argv[2].split(os.extsep)[-1]

        elif sys.argv[1].split(os.extsep)[-1] == 'csv' or sys.argv[1].split(os.extsep)[-1] == 'tsv':
            satellite_content = list(open(sys.argv[1], "r"))
            metadata_content = list(open(sys.argv[2], "r"))
            signature_path = sys.argv[1].split(os.extsep)[-2]
            formatting = sys.argv[1].split(os.extsep)[-1]

    except IndexError:
        print("""
        You probably missed one (or both) input file(s).\n\n 
        Quick reminder : files must be a .csv Kmer-SSR output file and a .metadata.txt metadata file
        """)
        sys.exit()

    metadata = hash_metadata(metadata_content)
    ssr_content = {}

    if satellite_content[0].strip('\n').split('\t')[0] == "#Sequence_Name":
        ssr_content = hash_kmerssr_output(satellite_content, True, formatting)

    elif satellite_content[0].strip('\n').split('\t')[0] != "#Sequence_Name":
        ssr_content = hash_kmerssr_output(satellite_content, False, formatting)

    signature = OrderedDict()
    signature["metadata"] = metadata
    signature["ssr"] = ssr_content

    with open('./' + signature_path + '.json', 'w') as file_output:
        json.dump(signature, file_output, indent=2, sort_keys=False)



if __name__ == "__main__":
    main()
