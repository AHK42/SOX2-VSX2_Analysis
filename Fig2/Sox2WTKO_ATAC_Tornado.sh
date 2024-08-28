#!/bin/bash 
#SBATCH -t 04:00:00
#SBATCH --job-name=Fig2_SOX2ATAC_WTKO
#SBATCH -c 16
#SBATCH --mem=119g
#SBATCH --output=Fig2_SOX2ATAC_WTKO.out 
#SBATCH --error=Fig2_SOX2ATAC_WTKO.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=ahk42@pitt.edu
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

# Define constants 
BLACKLIST="/bgfs/ialdiri/Genomes/mm10-blacklist.v2.bed.gz"
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# Define paths
ATAC_BAM_DIR="/bgfs/ialdiri/Pluto_Sox2/Bam"
ATAC_BIGWIG_DIR="/bgfs/ialdiri/Pluto_Sox2/bamCovBW"
BAM_FILES=("S2_WT_REP1.mLb.clN.sorted.bam" "S4_WT_REP1.mLb.clN.sorted.bam" "S6_KO_REP1.mLb.clN.sorted.bam" "S8_KO_REP1.mLb.clN.sorted.bam")

mkdir -p $ATAC_BIGWIG_DIR


for BAM in "${BAM_FILES[@]}"; do
    SAMPLE_NAME=$(basename "$BAM" | cut -d. -f1)
    bamCoverage \
        --bam "$ATAC_BAM_DIR/$BAM" \
        --outFileName "$ATAC_BIGWIG_DIR/${SAMPLE_NAME}.bigWig" \
        --binSize $WINDOW_SIZE \
        --normalizeUsing RPGC \
        --effectiveGenomeSize $CHROM_SIZE \
        --ignoreForNormalization chrX \
        --blackListFileName $BLACKLIST \
        --numberOfProcessors max \
        --verbose 
done

# Define bigWig files and peaks dir

BIGWIG_FILES=("$ATAC_BIGWIG_DIR/S2_WT_REP1.bigWig" "$ATAC_BIGWIG_DIR/S6_KO_REP1.bigWig")
PEAKS_DIR="/bgfs/ialdiri/Pluto_Sox2/Peaks"

############### Decreased ###############
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  "$PEAKS_DIR/DARs_sig_decreased.bed" \
    --binSize 10 \
    -o "decreased_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

plotHeatmap -m decreased_matrix.gz -out WT_KO_ATAC_Down.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 ATAC WT vs KO Decreased" \
    -z "1794 DARs" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none

############### Increased ###############
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  "$PEAKS_DIR/DARs_sig_increased.bed" \
    --binSize 10 \
    -o "increaed_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

plotHeatmap -m increased_matrix.gz -out WT_KO_ATAC_Up.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 ATAC WT vs KO Increased" \
    -z "582 DARs" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none

############### No Change ###############
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  "$PEAKS_DIR/noChange.bed" \
    --binSize $WINDOW_SIZE \
    -o "noChange_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

plotHeatmap -m noChange_matrix.gz -out WT_KO_ATAC_No_Change.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 ATAC WT vs KO No Change" \
    -z "84151 Peaks" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none