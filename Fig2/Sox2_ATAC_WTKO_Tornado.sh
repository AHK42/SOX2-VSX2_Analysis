#!/bin/bash

# Load necessary modules
module purge
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

# Define constants/paths
WINDOW_SIZE=10

# Define Paths (DAR analysis done by PLUTO)
ATAC_BIGWIG_DIR="/bgfs/ialdiri/Pluto_Sox2/bamCovBW"
PEAKS_DIR="/bgfs/ialdiri/Pluto_Sox2/Peaks" 

# Define BW File Paths
BIGWIG_FILES=("$ATAC_BIGWIG_DIR/S2_WT_REP1.bigWig" "$ATAC_BIGWIG_DIR/S6_KO_REP1.bigWig")

# Generate matrix and plots
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  $PEAKS_DIR/DARs_sig_decreased.bed  \
    --binSize $WINDOW_SIZE \
    -o "Decreased_CR_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

# Fig 2E/F
plotHeatmap -m Decreased_CR_matrix.gz -out Sox2_WTKO_ATAC_Decreased.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 WT vs KO ATAC" \
    -z "1794 DARs" \
    -x "" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none
