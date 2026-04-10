#!/bin/bash

# Load necessary modules
module purge
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

# Define constants/paths
WINDOW_SIZE=10

# Define Paths for Sox2CR
SOX2_BAM_DIR="/ix1/ialdiri/CR-ChIP/nfcore_runs/Sox2CR/results/02_alignment/bowtie2/target/dedup"
SOX2_BIGWIG_DIR="/ix1/ialdiri/CR-ChIP/bamCovBW/SOX2"
SOX2_BAM_FILES=("SOX2_S1_R1.target.dedup.sorted.bam") # only used 1 rep in these plots

mkdir -p $SOX2_BIGWIG_DIR

#  Loop over BAM files to generate bigWig files 
for BAM in "${SOX2_BAM_FILES[@]}"; do
   SAMPLE_NAME=$(basename "$BAM" | cut -d. -f1)
   bamCoverage \
       --bam "$SOX2_BAM_DIR/$BAM" \
       --outFileName "$SOX2_BIGWIG_DIR/${SAMPLE_NAME}.bigWig" \
       --binSize $WINDOW_SIZE \
       --normalizeUsing RPGC \
       --effectiveGenomeSize $CHROM_SIZE \
       --ignoreForNormalization chrX \
       --blackListFileName $BLACKLIST \
       --numberOfProcessors max \
       --verbose \
       --extendReads 
done

# Define paths for SOX2 ATAC Seq 
ATAC_BAM_DIR="/ix1/ialdiri/ATAC-Seq/Sox2_ATAC-Seq/outDir/bowtie2/merged_library"
ATAC_BIGWIG_DIR="/ix1/ialdiri/ATAC-Seq/Sox2_ATAC-Seq/bamCovBW"
BAM_FILES=("WT1_REP1.mLb.clN.sorted.bam" )

mkdir -p $ATAC_BIGWIG_DIR

# Generate bigWig Files
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
