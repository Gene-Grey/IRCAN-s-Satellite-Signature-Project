#!/bin/bash

function launchISSP () {
    projectName=$(date +%Y%m%d_%H%M%S)
# Le projet a pour nom la date et l'heure lors du lancement de la fonction

    mkdir $projectName
    mkdir $projectName/readsInputDir
    mkdir $projectName/metadataInputDir
    mkdir $projectName/outputDir

    mv *.fastq.* $projectName/readsInputDir
    mv *.id.txt $projectName/readsInputDir
    mv *.metadata.txt $projectName/metadataInputDir
    cp nextflow.config ./$projectName
    cp signature.nf ./$projectName

    cd $projectName
    nextflow signature.nf --reads_input_dir ./readsInputDir --metadata_input_dir ./metadataInputDir --output_dir ./outputDir --apiKey $1
# Lance le pipeline dans le dossier inputDir, depose les resultats dans le dossier outputDir

    cd ./outputDir
    mv $(readlink -f ./*) ./
    cd ..
    rm -rf work

    mutt -s "ProfessorX: ISSPipeline completed" $( printf -- '-a %q ' *.json ) -a ../timeline.html -a ../report.html $2
}

# Lancement de la fonction : launchISSP [adresse mail] /!\ il faut se trouver dans le dossier contenant les fichiers en entree /!\
# Pour l'instant : un fichier d'annotation par .fastq
# Pour modifier d'autres parametres, modifier le nextflow.config qui se trouve dans le meme dossier que le fichier pipeline (.nf)