#! /usr/env/nextflow

log.info """\
mode : $params.mode
inputs_dir : $params.inputs_dir
output_dir : $params.output_dir
"""

reads = Channel.create()
metadata = Channel.create()

Channel.fromFilePairs("${params.inputs_dir}/SRR*{.metadata.txt, .fastq.gz, .filt.fastq.zip}", size: 2, checkIfExists: 'true')
       .map { left, right ->
         def SRRCode = left
         def readsFile = right[0]
         def metadataFile = right[1]
         tuple(SRRCode, readsFile, metadataFile)
       }
       .into { reads; metadata }


process ComputeReadsFile {
  tag "Splitting $SRRCode reads files"

  input:
  set SRRCode, file(readsFile), file(metadataFile) from reads

  output:
  file(computedReadsFile) into ComputedReadsChannel

  script:
    if( params.mode == "ssr" ) {
      """
      unpigz -cp16 $readsFile | paste - - - - | cut -f 1,2 | sed 's/^@/>/' | tr "\t" "\n" > ${SRRCode}.fasta
      kmer-ssr -d -p $params.kmerSSR.periodMin-$params.kmerSSR.periodMax -r $params.kmerSSR.repeatMin -R $params.kmerSSR.repeatMax -l $params.kmerSSR.readLengthMin -L $params.kmerSSR.readLengthMax -t $params.kmerSSR.threads -i ${SRRCode}.fasta -o ${SRRCode}.tsv
      """
    }
}


process PrintSignatureFile {
  tag "Merging $SRRCode metadata and SSR signature files into json file"

  input:
  set SRRCode, file(metadataFile) from metadata
  file(computedReadsFile) from ComputedReadsChannel

  publishDir params.output_dir

  output:
  file "${SRRCode}.json"

  """

import os
import sys
import json

def hash_metadata(metadata_file):
    ""
        Takes the .csv or .tsv Kmer-SSR output file
        and formats it in a python dictionnary;
        second part of the signature file
    ""

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
# Recieves and checks both inputs, calls formatting funtions and outputs the .json file

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
# Recieves and checks both inputs, calls formatting funtions and outputs the .json file

    formatting = ""
    satellite_content = list(open($computedReadsFile, "r"))
    metadata_content = list(open($metadataFile, "r"))
    formatting = $computedReadsFile.split(os.extsep)[-1]

    metadata = hash_metadata(metadata_content)
    ssr_content = {}

    if satellite_content[0].strip('\n').split('\t')[0] == "#Sequence_Name":
        ssr_content = hash_kmerssr_output(satellite_content, True, formatting)

    elif satellite_content[0].strip('\n').split('\t')[0] != "#Sequence_Name":
        ssr_content = hash_kmerssr_output(satellite_content, False, formatting)

    signature = {**metadata, **ssr_content}

    with open('./' + $SRRCode + '.json', 'w') as file_output:
        json.dump(signature, file_output, indent=2, sort_keys=False)


if __name__ == "__main__":
    main()


  """
}


// workflow.onComplete {
//   def msg = template = """\
//         Pipeline execution summary
//         ---------------------------
//         Completed at: ${workflow.complete}
//         Duration    : ${workflow.duration}
//         Success     : ${workflow.success}
//         workDir     : ${workflow.workDir}
//         exit status : ${workflow.exitStatus}
//         """
//         .stripIndent()
// 
//     sendMail(
//       to: ${notification.to},
//       from: ${notification.from},
//       subject: "Signature pipeline on ${SRRCode} complete",
//       body: ${msg}.stripIndent(),
//       attach: "${output_dir}/${SRRCode}.json",
//     )
// }