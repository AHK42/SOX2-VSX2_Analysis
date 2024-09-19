#!/bin/bash
#SBATCH -t 00:20:00
#SBATCH --job-name=H3K
#SBATCH -c 16
#SBATCH --mem=119g
#SBATCH --output=H3K.out
#SBATCH --error=H3K.err

module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

#!
#!
#! NOT FINALIZED, DECIDING TO USE PLUTO OR NOT

# Define constants 
BLACKLIST="/bgfs/ialdiri/Genomes/mm10-blacklist.v2.bed.gz" #!mm10
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# Define Paths
H3K_BAM_DIR="/bgfs/ialdiri/Pluto_Sox2/Bam/H3K27Ac"
H3K_BIGWIG_DIR="/bgfs/ialdiri/Pluto_Sox2/bamCovBW/H3K27Ac"
H3K_BAM_FILES=("H3K27Ac_Adult_Rod_rep1.mLb.noPublish.bam" "H3K27Ac_Adult_Rod_rep2.mLb.noPublish.bam")

# mkdir -p $H3K_BIGWIG_DIR

# Generate bigWig Files
for BAM in "${H3K_BAM_FILES[@]}"; do
   SAMPLE_NAME=$(basename "$BAM" | cut -d. -f1)
   bamCoverage \
       --bam "$H3K_BAM_DIR/$BAM" \
       --outFileName "$H3K_BIGWIG_DIR/${SAMPLE_NAME}.bigWig" \
       --binSize $WINDOW_SIZE \
       --normalizeUsing RPGC \
       --effectiveGenomeSize $CHROM_SIZE \
       --ignoreForNormalization chrX \
       --blackListFileName $BLACKLIST \
       --numberOfProcessors max \
       --verbose \

done

PEAKS_DIR="/bgfs/ialdiri/Pluto_Sox2/Peaks/SOX2_VSX2"
BIGWIG_FILES=("$H3K_BIGWIG_DIR/H3K27Ac_Adult_Rod_rep1.bigWig" "$H3K_BIGWIG_DIR/H3K27Ac_Adult_Rod_rep2.bigWig" )

# Generate matrix and plots
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  "$PEAKS_DIR/Sox2_Vsx2_overlap_peaks.bed" "$PEAKS_DIR/Sox2_peaks_unique.bed" "$PEAKS_DIR/Vsx2_peaks_unique.bed"  \
    --binSize $WINDOW_SIZE \
    -o "H3K27Ac_PlutoPeaks_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

    plotProfile -m H3K27Ac_PlutoPeaks_matrix.gz \
    -out H3K27Ac_plot_PlutoPeaks.png \
    --plotType lines \
    --dpi 600 \

PEAKS_DIR="/bgfs/ialdiri/CR-ChIP/Peaks"

computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  "$PEAKS_DIR/shared.bed" "$PEAKS_DIR/sox2_unique.bed" "$PEAKS_DIR/vsx2_9k_unique.bed"  \
    --binSize $WINDOW_SIZE \
    -o "H3K27Ac_MyPeaks_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

    plotProfile -m H3K27Ac_MyPeaks_matrix.gz \
    -out H3K27Ac_plot_MyPeaks.png \
    --plotType lines \
    --dpi 600 \



#* SOXCR + H3K27ac Tornado Plot

SOX2_BIGWIG_DIR="/bgfs/ialdiri/Pluto_Sox2/bamCovBW/SOX2"
BIGWIG_FILES=("$SOX2_BIGWIG_DIR/sample_SOX2_S1_R1.bigWig" "$H3K_BIGWIG_DIR/H3K27Ac_Adult_Rod_rep1.bigWig" "$H3K_BIGWIG_DIR/H3K27Ac_Adult_Rod_rep2.bigWig")
PEAKS_DIR="/bgfs/ialdiri/Pluto_Sox2/Peaks"

computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R "$PEAKS_DIR/HMM_States_Sox2_Overlap_mm9_mm10_liftover.bed"  \
    --binSize $WINDOW_SIZE \
    -o "SOX2_H3K27Ac_Overlap_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

plotHeatmap -m SOX2_H3K27Ac_Overlap_matrix.gz -out SOX2_H3K27Ac_Overlap.png \
    --colorMap 'Blues' \
    --verbose \
    -T "SOX2 and H3K27Ac Overlap" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none