#!/bin/bash 

# Load necessary modules
module purge    
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

# Define constants
BLACKLIST="/bgfs/ialdiri/Genomes/mm10-blacklist.v2.bed.gz"
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# Define Paths for Sox2CR
SOX2_BAM_DIR="/bgfs/ialdiri/CR-ChIP/nfcore_runs/Sox2CR/results/02_alignment/bowtie2/target/dedup"
SOX2_BIGWIG_DIR="/bgfs/ialdiri/CR-ChIP/bamCovBW/SOX2"
SOX2_BAM_FILES=("SOX2_S1_R1.target.dedup.sorted.bam")

mkdir -p $SOX2_BIGWIG_DIR

# Loop over BAM files to generate bigWig files
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
       --extendReads  # Specific to C&R
done

# Define paths for SOX2 ATAC Seq 
ATAC_BAM_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_ATAC-Seq/outDir/bowtie2/merged_library"
ATAC_BIGWIG_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_ATAC-Seq/bamCovBW"
BAM_FILES=("WT1_REP1.mLb.clN.sorted.bam" )

mkdir -p $ATAC_BIGWIG_DIR

Generate bigWig Files
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

BIGWIG_FILES=("$SOX2_BIGWIG_DIR/SOX2_S3_R1.bigWig" "$ATAC_BIGWIG_DIR/WT1_REP1.bigWig")
PEAKS_DIR="/bgfs/ialdiri/Sox2_ATAC/Peaks"

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

# Fig 1A
plotHeatmap -m SOX2CR_ATAC.gz -out SOX2CR_ATAC.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 CR vs ATAC E14.5" \
    -x "" \
    --zMax 25 160 \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none

#Fig 1G 
BIGWIG_FILES=("$STAGES_BIGWIG_DIR/E14.5_REP1.bigWig" "$STAGES_BIGWIG_DIR/P7_REP1.bigWig" "$STAGES_BIGWIG_DIR/P21_REP1.bigWig")
PEAKS_DIR="/bgfs/ialdiri/Sox2_ATAC/Peaks" 

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