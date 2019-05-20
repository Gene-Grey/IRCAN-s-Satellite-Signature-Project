#usr/bin/bash

IFS=$'\n'

nom_fichier_fastq=$1;
fastq=$2;
 
id_patient=$(echo $nom_fichier_fastq | cut -d_ -f1);

printf "satellite_signature_$depth\n" >> info_$id_patient.txt;

time perl k_seek_4_2.pl $id_patient\_SRR190848_2.filt.fastq repeats_$id_patient;

for line in $(sort -k2 -g repeats_$id_patient.total | tac | head -$depth); do
	printf "\t$line\n" >> info_$id_patient.txt
done

perl treat_info.pl info_$id_patient.txt > signature_$id_patient.json;

#cd ../results_fasta
