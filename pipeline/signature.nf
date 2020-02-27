#!/$HOME/nextflow

def helpMessage() {
    log.info"""
    =========================================
     ISSB v${params.version}
    =========================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run signature.nf --reads_input_dir ./inputs --metadata_input_dir ./inputs --output_dir ./outputs --kmerSSR.threads 16
    
    Required arguments:
        --sequence_mode                Configuration profile to use. <fastq_files, ncbi_ids>
        --reads_input_dir              Specifies the reads input files folder.
        --metadata_input_dir           Specifies the metadata input files folder.
         
    Performance options:
        --kmerSSR.threads              Runs multi-threading for kmer-ssr processing.

    Output File options:
        --output_dir                   Specifies the directory in which the files are published (default is the working directory).
        
    Kmer-ssr options:
        --kmerSSR.periodMin            Minimum period size in a single SSR
        --kmerSSR.periodMax            Maximum period size in a single SSR
        --kmerSSR.repeatMin            Minimum value for the number of repeat in a single SSR
        --kmerSSR.repeatMax            Maximum value for the number of repeat in a single SSR
        --kmerSSR.readLengthMin        Minimum number of bases for a read to be computed
        --kmerSSR.readLengthMax        Maximum number of bases for a read to be computed
        --kmerSSR.ssrSizeTreshold

    Report options :
        --report.enabled               Enables the Nexflow run report
        --timeline.enabled             Enables the Nextflow timeline report
    """.stripIndent()
}


log.info """=======================================================
ISSB v${params.version}"
======================================================="""
def summary = [:]
summary['Pipeline Name']                                             = 'ISSB'
summary['Help Message']                                              = params.help
summary['Pipeline Version']                                          = params.version
summary['Current home']                                              = "$HOME"
summary['Current user']                                              = "$USER"
summary['Current path']                                              = "$PWD"
summary['Sequence gathering mode']                                   = params.sequence_mode
summary['Max forking option']                                        = params.threads
summary['NCBI API Key']                                              = params.apiKey
summary['Kmer-SSR minimum SSR period size']                          = params.kmerSSR.periodMin
summary['Kmer-SSR maximum SSR period size']                          = params.kmerSSR.periodMax
summary['Kmer-SSR minimum SSR size']                                 = params.kmerSSR.ssrSizeTreshold
summary['Kmer-SSR minimum SSR repeat size']                          = params.kmerSSR.repeatMin
summary['Kmer-SSR maximum SSR repeat size']                          = params.kmerSSR.repeatMax
summary['Kmer-SSR minimum SSR period size']                          = params.kmerSSR.readLengthMin
summary['Kmer-SSR maximum SSR period size']                          = params.kmerSSR.readLengthMax
if(params.sequence_mode == "files") summary['Reads input dir']       = params.reads_input_dir
if(params.sequence_mode == "ncbi_ids") summary['Metadata input dir'] = params.metadata_input_dir
summary['File output dir']                                           = params.output_dir
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "======================================================="

if (params.help) {
    helpMessage()
    exit 0
}

ids = []
Reads = Channel.fromPath("${params.reads_input_dir}/*.*sv")
               .map { file -> 
                def key = file.getSimpleName()
                return tuple(key, file)
               }


if(params.sequence_mode == "ncbi_ids") {
    Channel.fromPath("${params.reads_input_dir}/*.id.txt")
           .subscribe onNext: {
                all_ids = it.readLines()

                for( id in all_ids ) {
                    ids.add(id)
                }
            }

    Reads = Channel.fromSRA(ids, apiKey: params.apiKey)
        .flatMap { left, right ->
            def SRRCode = left
            switch(right) {
                case { right.getClass() == java.util.ArrayList && right.size() == 2 }:
                    def forward = right[0]
                    def reverse = right[1]
                    return [tuple(SRRCode.concat("_1"), forward), tuple(SRRCode.concat("_2"), reverse)]

                case { right.getClass() == java.util.ArrayList && right.size() == 3 }:
                    def forward = right[1]
                    def reverse = right[2]
                    return [tuple(SRRCode.concat("_1"), forward), tuple(SRRCode.concat("_2"), reverse)]

                case right.getClass() == nextflow.file.http.XPath:
                    def sequence = right
                    return [tuple(SRRCode, sequence)]
            }
        }
}

else if(params.sequence_mode == "fastq_files") {
    Reads = Channel.fromPath("${params.reads_input_dir}/*.fa*")
        .map { file ->
            def key = file.getSimpleName()
            ids.add(key)
            return tuple(key, file)
        }
}


process ComputeReadsFile {
    tag "Processing $fileCode reads files using kmer-ssr"
    maxForks params.threads

    input:
    set fileCode, file(readsFile) from Reads

    output:
    tuple fileCode, file("${fileCode}.tsv") into ComputedReads

    script:
    """
    unpigz -cp16 $readsFile | paste - - - - | cut -f 1,2 | sed 's/^@/>/' | tr "\\t" "\\n" > ${fileCode}.fasta
    kmer-ssr -d -p ${params.kmerSSR.periodMin}-${params.kmerSSR.periodMax} -n ${params.kmerSSR.ssrSizeTreshold} -r ${params.kmerSSR.repeatMin} -R ${params.kmerSSR.repeatMax} -l ${params.kmerSSR.readLengthMin} -L ${params.kmerSSR.readLengthMax} -i ${fileCode}.fasta -o ${fileCode}.tsv
    """
}

Metadata = Channel.fromPath("${params.metadata_input_dir}/*.metadata.txt")
        .map { file ->
            def key = file.getSimpleName()
            return tuple(key, file)
        }

AssociatedFiles = ComputedReads
               .join(Metadata)


process PrintSignatureFile {
  tag "Merging $fileCode metadata and SSR signature files into complete signature json file"

  publishDir params.output_dir

  input:
  set fileCode, file(computedReadsFile), file(metadataFile) from AssociatedFiles

  output:
  file "${fileCode}.json"

  script:
"""
#!/usr/bin/env python3

import os
import sys
import json
from collections import OrderedDict

def hash_metadata(metadata_file):
    metadata = {}
    remarks = []

    for line in metadata_file:
        tab_split_line = line.strip("\\n").split("\\t")

        if len(tab_split_line) == 2:
            metadata[tab_split_line[0]] = tab_split_line[1]

        elif len(tab_split_line) == 3 and tab_split_line[0] == '':
            remarks.append(tab_split_line[2])

    metadata.update({'remarks': remarks})

    return metadata

def hash_kmerssr_output(kmerssr_output_file, has_header, formatting_key):
    kmerssr_dict = {}

    for line in kmerssr_output_file:
        if has_header:
            has_header = False
            continue

        tab_split_line = line.strip('\\n').split(formatting_key)
        ssr_key = tab_split_line[1]
        repeats_key = int(tab_split_line[2])

        try:
            kmerssr_dict[ssr_key]
        except KeyError:
            kmerssr_dict[ssr_key] = {}
            kmerssr_dict[ssr_key]['total'] = 0

        try:
            kmerssr_dict[ssr_key][repeats_key]
        except KeyError:
            kmerssr_dict[ssr_key][repeats_key] = 0

        kmerssr_dict[ssr_key][repeats_key] += 1
        kmerssr_dict[ssr_key]['total'] += 1

    ordered_list = sorted(kmerssr_dict, key=lambda x: kmerssr_dict[x]['total'])
    ssr_dict = {}

    for key in ordered_list:
        ssr_dict[key] = kmerssr_dict[key]

    return ssr_dict


def main():
    signature_path = ''
    formatting = ''

    metadata_content = list(open("./$metadataFile", 'r'))
    satellite_content = list(open("./$computedReadsFile", 'r'))

    signature_path = "./$computedReadsFile"
    signature_path = signature_path.split(os.extsep)[-2]

    formatting = "./$computedReadsFile"
    formatting = formatting.split(os.extsep)[-1]

    if formatting == 'csv':
        formatting_key = ','

    elif formatting == 'tsv':
        formatting_key = '\t'

    metadata = hash_metadata(metadata_content)
    ssr_content = {}

    if satellite_content[0].strip('\\n').split(formatting_key)[0] == '#Sequence_Name':
        ssr_content = hash_kmerssr_output(satellite_content, True, formatting_key)

    elif satellite_content[0].strip('\\n').split(formatting_key)[0] != '#Sequence_Name':
        ssr_content = hash_kmerssr_output(satellite_content, False, formatting_key)

    signature = OrderedDict()
    signature['metadata'] = metadata
    signature['ssr'] = ssr_content

    with open('./' + signature_path + '.json', 'w') as file_output:
        json.dump(signature, file_output, indent=2, sort_keys=False)

if __name__ == "__main__":
    main()
"""
}