#!/usr/bin/env python3

import sys
import os
import re

def generateMetadata(file, outpath):
    metadata_csv = open(file, "r").readlines()
    csv_first_line = True
    firstline = []

    for line in metadata_csv:
        paired_counter = 1
        metadata = []

        if csv_first_line:
            firstline = line.strip('\n').split(",")
            csv_first_line = False
            continue

        metadata_line = line.strip('\n').split(",")
        metadata_filename = metadata_line[0]

        for i in range(0,len(metadata_line)):
            match = re.search("^paired([_\s]end)?$", metadata_line[i], re.IGNORECASE)

            try:
                metadata_line[i] = int(metadata_line[i])
            except ValueError:
                pass

            metadata.append((firstline[i], metadata_line[i]))

            if match:
                paired_counter += 1

        if paired_counter == 1:
            f = open(outpath + metadata_filename +'.metadata.txt', 'w')
            sys.stdout = f
            for element in metadata:
                print(*element, sep='\t')
            f.close()

        elif paired_counter == 2:
            for i in range(0, paired_counter, 1):
                f = open(outpath + metadata_filename + '_' + str(i+1) + '.metadata.txt', 'w')
                sys.stdout = f
                for element in metadata:
                    print(*element, sep='\t')
                f.close()


def main():
    generateMetadata(sys.argv[1], sys.argv[2])


if __name__ == "__main__":
    main()