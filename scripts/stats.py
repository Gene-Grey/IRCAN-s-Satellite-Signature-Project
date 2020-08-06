import gower
import json
import pandas as pd
import sys

from math import floor
from matplotlib import pyplot as plt
from os import listdir
from os.path import isfile, join
from scipy.cluster.hierarchy import dendrogram, linkage
from scipy.spatial import distance_matrix
from time import sleep



def getSignatureStats(signature):
    n_unique_motifs = 0
    n_motifs = 0
    total_motif_length = []
    total_repeats = []
    total_sequence_length = []
    bp_covered = 0
    min_len = 300
    min_len_motifs = []
    max_len = 0
    max_len_motifs = []
    max_occurrence = 0
    max_occurrences_motifs = []
    max_repeat = 0
    max_repeat_motifs = []
    max_sequence_length = 0
    max_sequence_length_motif = []

    for motif in signature['ssr'].keys():
        n_unique_motifs += 1
        bp_covered += signature['ssr'][motif]["total"]*len(motif)

        if signature['ssr'][motif]["total"] > max_occurrence:
            max_occurrences_motifs = []
            max_occurrences_motifs.append(motif)
            max_occurrence = signature['ssr'][motif]["total"]

        elif signature['ssr'][motif]["total"] == max_occurrence:
            max_occurrences_motifs.append(motif)

        if signature['ssr'][motif]["total"]*len(motif) > max_sequence_length:
            max_sequence_length_motif = []
            max_sequence_length_motif.append(motif)
            max_sequence_length = signature['ssr'][motif]["total"]*len(motif)

        elif signature['ssr'][motif]["total"] * \
            len(motif) == max_sequence_length:
            max_sequence_length_motif.append(motif)

        if len(motif) > max_len:
            max_len_motifs = []
            max_len_motifs.append(motif)
            max_len = len(motif)

        elif len(motif) == max_len:
            max_len_motifs.append(motif)

        if len(motif) < min_len:
            min_len_motifs = []
            min_len_motifs.append(motif)
            min_len = len(motif)

        elif len(motif) == min_len:
            min_len_motifs.append(motif)

        for repeat in signature['ssr'][motif]:
            if repeat == "total":
                continue

            else:
                n_motifs += 1
                total_repeats.append(int(repeat))

                if int(repeat) > max_repeat:
                    max_repeat_motifs = []
                    max_repeat_motifs.append(motif)
                    max_repeat = int(repeat)
                elif int(repeat) == max_repeat:
                    max_repeat_motifs.append(motif)

                total_motif_length.append(len(motif))
                total_sequence_length.append(int(repeat)*len(motif))

# Average motif length and associated standard deviations
    average_motif_length = sum(total_motif_length) / len(total_motif_length)
    var_motif_length = 0

    for x in total_motif_length:
        var_motif_length += (average_motif_length - x)**2

    var_motif_length = var_motif_length / len(total_motif_length)
# Average repeat sequence length and associated standard deviations
    average_repeat_sequence_length = sum(total_sequence_length) / \
                                        len(total_sequence_length)
    var_repeat_sequence_length = 0

    for x in total_sequence_length:
        var_repeat_sequence_length += (average_repeat_sequence_length - x)**2

    var_repeat_sequence_length = var_repeat_sequence_length / \
                                    len(total_sequence_length)
# Average repeat and associated standard deviations
    average_repeat = sum(total_repeats) / len(total_repeats)
    var_repeat = 0

    for x in total_repeats:
        var_repeat += (average_repeat - x)**2

    var_repeat = var_repeat / len(total_repeats)

    print(n_motifs, "motifs in the signature, with", n_unique_motifs, \
            "unique motifs, covering", bp_covered, "bp")

    print("\nLongest motif(s)\n\t", max_len_motifs, "\tlength :", max_len, \
            "bp\nShortest motif(s)\n\t", min_len_motifs, "\tlength :",  \
            min_len, "bp\n")

    print("Most repeated motif(s)\n\t", max_occurrences_motifs, \
            "\tnumber of occurrences :", max_occurrence, \
            "total occurrences\n")

    print("Longest sequence(s)\n\t", max_sequence_length_motif, \
            "\tsequence covered :", max_sequence_length, "bp\n")

    print("Longest repeates(s)\n\t", max_repeat_motifs, \
            "\trepeat :", max_repeat, "\n")

    print("Average motif length\n\t", average_motif_length, \
            "bp\nStandard deviation : ", var_motif_length,"\n")

    print("Average repeat sequence length\n\t", average_repeat_sequence_length, \
            "bp\nStandard deviation\n\t", var_repeat_sequence_length,"\n")

    print("Average repeat\n\t", average_repeat, "\nStandard deviation\n\t", \
            var_repeat, "\n\n")

    return max_len, max_repeat, max_occurrence


def agregateSignatures(signature_1, signature_2):
    for motif in signature_2["ssr"].keys():
        try:
            signature_1["ssr"][motif]
        except KeyError:
            signature_1["ssr"][motif] = signature_2["ssr"][motif]
            continue
        else:
            for repeat in signature_2["ssr"][motif]:
                try:
                    signature_1["ssr"][motif][repeat]

                except KeyError:
                    signature_1["ssr"][motif][repeat] = 0
                    continue

                signature_1["ssr"][motif][repeat] += signature_2["ssr"][motif][repeat]

    return signature_1


def getCommonSignature(signatures):
    common_signature = dict(signatures[0])

    for signature in range(1, len(signatures)):
        motif_wanted_list = []
        repeat_wanted_list = []

        for motif in common_signature["ssr"].keys():
            try:
                signatures[signature]["ssr"][motif]
            except KeyError:
                motif_wanted_list.append(motif)
            else:
                for repeat in common_signature["ssr"][motif]:
                    try:
                        signatures[signature]["ssr"][motif][repeat]
                    except KeyError:
                        repeat_wanted_list.append((motif, repeat))
                        continue
                    else:
                        common_signature["ssr"][motif][repeat] += signatures[signature]["ssr"][motif][repeat]

        for motif in motif_wanted_list:
            del common_signature["ssr"][motif]

        for repeat in repeat_wanted_list:
            del common_signature["ssr"][repeat[0]][repeat[1]]

    for motif in common_signature["ssr"]:
        for repeat in common_signature["ssr"][motif]:
            common_signature["ssr"][motif][repeat] = floor(common_signature["ssr"][motif][repeat] / len(signatures))

    return common_signature


def getGlobalSignature(signatures):
    dataset_signature = {"ssr" : {}}
    dataset_signature = agregateSignatures(dataset_signature, signatures[0])

    for signature in range(1, len(signatures)):
        dataset_signature = agregateSignatures(dataset_signature, signatures[signature])

    return dataset_signature


def mergePairedEnds(signatures, labels):
    merged_signatures = []
    merged_labels = []
    
    for i in range(0, len(signatures), 2):
        merged_signatures.append(agregateSignatures(signatures[i], signatures[i+1]))

        if labels[i].split("_")[0] == labels[i+1].split("_")[0]:
            merged_labels.append(labels[i].split("_")[0])

    return merged_signatures, merged_labels


def getTopX(signature, reverse, x=-1):
    top = sorted(signature["ssr"], key=lambda motif: signature['ssr'][motif]['total'], reverse=reverse)

    if x > 0:
        return top[0:x-1]

    elif x <= 0:
        return top


def getTopXSsrMatix(signatures, x, index):
    data = []
    labels = [i for i in range(1, x)]

    for signature in signatures:
        top_X = getTopX(signature, True, x)
        data.append(top_X)

    df = pd.DataFrame(data, columns=labels, index=index)

    return df


def convertToTotalScore(signatures, w1=1, w2=1, w3=1, w4=1):
    score_signatures = []

    global_signature = getGlobalSignature(signatures)
    max_len, max_repeat, max_occurrence = getSignatureStats(global_signature)

    for signature in signatures:
        signature_copy = dict(signature)
        ordered_motifs = getTopX(signature, False)
        max_rank = len(ordered_motifs)

        for i in range(0, len(ordered_motifs)):
            signature_copy["ssr"][ordered_motifs[i]]["total"] = 0
            scores = []

            for motif in signature_copy["ssr"][ordered_motifs[i]].keys():
                try:
                    int(motif)
                except ValueError:
                    continue
                else:
                    signature_copy["ssr"][ordered_motifs[i]][motif] = \
                        len(ordered_motifs[i]) * w1 / max_len * max_occurrence \
                            + int(motif) * w2 / max_repeat * max_occurrence \
                            + w3 * signature["ssr"][ordered_motifs[i]]["total"] \
                            + i * w4 / max_rank * max_occurrence
                    scores.append(signature_copy["ssr"][ordered_motifs[i]][motif])

            signature_copy["ssr"][ordered_motifs[i]]["total"] = sum(scores)

        score_signatures.append(signature_copy)

    return score_signatures


def getSignaturesDistanceMatrix(signatures, call_type, index):
    data = []
    labels = []
    
    if call_type == "global":
        general_signature = getGlobalSignature(signatures)

        for motif in general_signature["ssr"].keys():
            for repeat in general_signature["ssr"][motif].keys():
                repeat_code = (motif, repeat)
                labels.append(''.join(repeat_code))

        for signature in signatures:
            signature_data = []

            for motif in general_signature["ssr"].keys():

                for repeat in general_signature["ssr"][motif].keys():

                    try:
                        signature["ssr"][motif][repeat]
                    except KeyError:
                        signature_data.append(0)
                    else:
                        signature_data.append(signature["ssr"][motif][repeat])

            data.append(signature_data)

    elif call_type == "common":
        common_signature = getCommonSignature(signatures)

        for motif in common_signature["ssr"].keys():
            for repeat in common_signature["ssr"][motif].keys():
                repeat_code = (motif, repeat)
                labels.append(''.join(repeat_code))

        for signature in signatures:
            signature_data = []

            for motif in common_signature["ssr"].keys():

                for repeat in common_signature["ssr"][motif].keys():

                    try:
                        signature["ssr"][motif][repeat]
                    except KeyError:
                        signature_data.append(0)
                    else:
                        signature_data.append(signature["ssr"][motif][repeat])

            data.append(signature_data)

    df = pd.DataFrame(data, columns=labels, index=index)

    return df


def showTree(clustering, leaf_label):
    plt.figure(figsize=(25, 10))
    plt.title('Hierarchical Clustering Dendrogram')
    plt.xlabel('sample index')
    plt.ylabel('distance')
    dendrogram(
        clustering,
        leaf_rotation=90.,  # rotates the x axis labels
        leaf_font_size=8.,  # font size for the x axis labels
        labels=None
    )
    plt.show()


def main():
    onlyfiles = [f for f in listdir(sys.argv[1]) if isfile(join(sys.argv[1], f))]
    signatures = []
    labels = []
    file = 0

    while file < len(onlyfiles):
        
        if onlyfiles[file].split(".")[1] == "json":
            with open(onlyfiles[file], 'r') as signature_file:
                labels.append(onlyfiles[file])
                signature_data = signature_file.read()
                signature_obj = json.loads(signature_data)
                signature_file.close()
                signatures.append(signature_obj)
                file += 1
        else:
            onlyfiles.remove(onlyfiles[file])

    signatures, labels = mergePairedEnds(signatures, onlyfiles)

    print("GENERAL SIGNATURE\n")
    general_signature = getGlobalSignature(signatures)
    getSignatureStats(general_signature)
    print("COMMON SIGNATURE\n")
    common_signature = getCommonSignature(signatures)
    getSignatureStats(common_signature)

#    top_X_matrix = getTopXSsrMatix(signatures, 15, labels)
#    M1 = linkage(gower.gower_matrix(top_X_matrix),  method='complete')
#    showTree(M1, labels)

#    general_signatures_matrix = getSignaturesDistanceMatrix(signatures, "global", labels)
#    common_signature_matrix = getSignaturesDistanceMatrix(signatures, "common", labels)
#    M2_1 = linkage(general_signatures_matrix, method='complete', metric = 'euclidean')
#    M2_2 = linkage(common_signature_matrix, method='complete', metric = 'euclidean')
#    showTree(M2_1, labels)
#    showTree(M2_2, labels)

#    scores_signatures = convertToTotalScore(signatures, w3 = 0.0001, w4 = 0.0001)
#    total_matrix = getSignaturesDistanceMatrix(scores_signatures, "global", labels)
#    M3 = linkage(total_matrix, method='complete', metric = 'euclidean')
#    showTree(M3, labels)



if __name__ == "__main__":
    main()