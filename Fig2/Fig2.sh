#!/bin/bash 

# Load necessary modules
module purge    
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

# Define constants
BLACKLIST="/ix1/ialdiri/Genomes/mm10-blacklist.v2.bed.gz"
CHROM_SIZE="2650000000"
WINDOW_SIZE=10


BIGWIG_FILES=("$SOX2_BIGWIG_DIR/SOX2_S3_R1.bigWig" "$ATAC_BIGWIG_DIR/WT1_REP1.bigWig")
PEAKS_DIR="/ix1/ialdiri/Sox2_ATAC/Peaks"

# Generate matrix and plots
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R "$PEAKS_DIR/Sox2CR_ATAC_int.bed" \
    --binSize $WINDOW_SIZE \
    -o "SOX2CR_ATAC.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

# Fig 1A/B
plotHeatmap -m SOX2CR_ATAC.gz -out SOX2CR_ATAC.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 CR vs ATAC E14.5" \
    -x "" \
    --zMax 25 160 \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none

# Fig 2F 
BIGWIG_FILES=("$STAGES_BIGWIG_DIR/E14.5_REP1.bigWig" "$STAGES_BIGWIG_DIR/P7_REP1.bigWig" "$STAGES_BIGWIG_DIR/P21_REP1.bigWig")
PEAKS_DIR="/ix1/ialdiri/Sox2_ATAC/Peaks" 

computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R "$PEAKS_DIR/Sox2CR_E14.5_WT_ATAC_int.bed" \
    --binSize $WINDOW_SIZE \
    -o "SOX2_Bound_ATAC_Stages.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

# Plot median instead of mean 
plotProfile -m SOX2_Bound_ATAC_Stages.gz -out SOX2_Bound_ATAC_Stages.png \
    --verbose \
    -T "Sox2 ATAC Stages" \
    --dpi 600 \
    --perGroup \
    -z "3412 Peaks" \
    --averageType median