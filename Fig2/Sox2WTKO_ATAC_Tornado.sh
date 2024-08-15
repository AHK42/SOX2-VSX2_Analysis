#!/bin/bash 
#SBATCH -t 08:00:00
#SBATCH --job-name=deepTools
#SBATCH -c 16
#SBATCH --mem=119g
#SBATCH --output=DT.out 
#SBATCH --error=DT.err         
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=ahk42@pitt.edu
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools


# Step 1: Generate bigWig files using deeptools

# Define constant paths 
BLACKLIST="/bgfs/ialdiri/Genomes/mm10-blacklist.v2.bed.gz"
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# Define paths for SOX2 ATAC Seq (WT and KO)
ATAC_BAM_DIR="/bgfs/ialdiri/Pluto_Sox2/Bam"
ATAC_BIGWIG_DIR="/bgfs/ialdiri/Pluto_Sox2/bamCovBW"
# Bam files to process
BAM_FILES=("S2_WT_REP1.mLb.clN.sorted.bam" "S4_WT_REP1.mLb.clN.sorted.bam" "S6_KO_REP1.mLb.clN.sorted.bam" "S8_KO_REP1.mLb.clN.sorted.bam")

mkdir -p $ATAC_BIGWIG_DIR

# Loop over BAM files to generate bigWig files

# for BAM in "${BAM_FILES[@]}"; do
#     SAMPLE_NAME=$(basename "$BAM" | cut -d. -f1)
#     bamCoverage \
#         --bam "$ATAC_BAM_DIR/$BAM" \
#         --outFileName "$ATAC_BIGWIG_DIR/${SAMPLE_NAME}.bigWig" \
#         --binSize $WINDOW_SIZE \
#         --normalizeUsing RPGC \
#         --effectiveGenomeSize $CHROM_SIZE \
#         --ignoreForNormalization chrX \
#         --blackListFileName $BLACKLIST \
#         --numberOfProcessors max \
#         --verbose 
# done

# Define BW Files

BIGWIG_FILES=("$ATAC_BIGWIG_DIR/S2_WT_REP1.bigWig" "$ATAC_BIGWIG_DIR/S6_KO_REP1.bigWig")
PEAKS_DIR="/bgfs/ialdiri/Pluto_Sox2/Peaks"

# computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
#     -S "${BIGWIG_FILES[@]}" \
#     -R  "$PEAKS_DIR/DARs_sig_decreased.bed" \
#     --binSize $WINDOW_SIZE \
#     -o "decreased_matrix.gz" \
#     --sortRegions descend \
#     --sortUsing mean \
#     --missingDataAsZero \
#     --verbose -p max --skipZeros --smartLabels

plotHeatmap -m decreased_matrix.gz -out WT_KO_ATAC_Down.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 ATAC WT vs KO Decreased" \
    -z "Peaks" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none

# computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
#     -S "${BIGWIG_FILES[@]}" \
#     -R  "$PEAKS_DIR/DARs_sig_increased.bed" \
#     --binSize $WINDOW_SIZE \
#     -o "increaed_matrix.gz" \
#     --sortRegions descend \
#     --sortUsing mean \
#     --missingDataAsZero \
#     --verbose -p max --skipZeros --smartLabels

plotHeatmap -m increased_matrix.gz -out WT_KO_ATAC_Up.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 ATAC WT vs KO Increased" \
    -z "Peaks" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none

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
    -z "Peaks" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none