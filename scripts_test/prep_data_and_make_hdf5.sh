#!/usr/bin/env bash

##simdata generation - install simdna
densityMotifSimulation.py --prefix gata --motifNames GATA_disc1 --max-motifs 3 --min-motifs 1 --mean-motifs 2 --seqLength 200 --numSeqs 1000
densityMotifSimulation.py --prefix tal --motifNames TAL1_known1 --max-motifs 3 --min-motifs 1 --mean-motifs 2 --seqLength 200 --numSeqs 1000
densityMotifSimulation.py --prefix talgata --motifNames GATA_disc1 TAL1_known1 --max-motifs 3 --min-motifs 1 --mean-motifs 2 --seqLength 200 --numSeqs 1000

#cleanup the _info files
rm *_info.txt

#zip things up
gzip -f *.simdata
gzip -f *.fa

###
#make the labels file without a title, to be shuffled
zcat DensityEmbedding_prefix-gata_motifs-GATA_disc1_min-1_max-3_mean-2_zeroProb-0_seqLength-200_numSeqs-1000.simdata.gz | perl -lane 'if ($. > 1) {print "$F[0]\t1\t0"}' > labels_without_title.txt
zcat DensityEmbedding_prefix-tal_motifs-TAL1_known1_min-1_max-3_mean-2_zeroProb-0_seqLength-200_numSeqs-1000.simdata.gz | perl -lane 'if ($. > 1) {print "$F[0]\t0\t1"}' >> labels_without_title.txt
zcat DensityEmbedding_prefix-talgata_motifs-GATA_disc1+TAL1_known1_min-1_max-3_mean-2_zeroProb-0_seqLength-200_numSeqs-1000.simdata.gz | perl -lane 'if ($. > 1) {print "$F[0]\t1\t1"}' >> labels_without_title.txt

#concatenate the fasta files to be one per line
zcat DensityEmbedding_prefix-gata_*.fa.gz DensityEmbedding_prefix-tal_*.fa.gz DensityEmbedding_prefix-talgata*.fa.gz | perl -lane 'BEGIN {$title=undef} {if ($.%2==1) {$title=$_} else {print $title."|".$_}}' | gzip -c > concatenated_single_line_inputs.gz

#shuffle the lines
shuffle_corresponding_lines labels_without_title.txt concatenated_single_line_inputs.gz

#make the final inputs labels files from the shuffled lines
echo $'id\tgata\ttal' > labels.txt
cat shuffled_labels_without_title.txt >> labels.txt
gzip -f labels.txt
zcat shuffled_concatenated_single_line_inputs.gz | perl -lane '($id, $seq) = split(/\|/, $_); print($id); print($seq)' | gzip -c > inputs.fa.gz

#remove the intermediate files
rm shuffled_labels_without_title.txt
rm labels_without_title.txt
rm concatenated_single_line_inputs.gz
rm shuffled_concatenated_single_line_inputs.gz
rm DensityEmbedding*.fa.gz

mkdir splits
#make the splits
zcat labels.txt.gz | perl -lane 'if ($.%10 !=1 and $.%10 != 2) {print $F[0]}' | gzip -c > splits/train.txt.gz
zcat labels.txt.gz | perl -lane 'if ($.%10==1 and $. > 1) {print $F[0]}' | gzip -c > splits/valid.txt.gz
zcat labels.txt.gz | perl -lane 'if ($.%10==2) {print $F[0]}' | gzip -c > splits/test.txt.gz

make_hdf5 --yaml_configs make_hdf5_yaml/* --output_dir .
