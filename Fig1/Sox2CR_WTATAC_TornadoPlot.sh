#!/bin/bash 
#SBATCH -t 01:00:00
#SBATCH --job-name=deepTools
#SBATCH -c 16
#SBATCH --mem=119g
#SBATCH --output=Sox2_WTATAC.out 
#SBATCH --error=Sox2_WTATAC.err         
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=ahk42@pitt.edu
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

# Step 1: Generate bigWig files using deeptools

# Define constant paths 
BLACKLIST="/bgfs/ialdiri/Genomes/mm10-blacklist.v2.liftover.mm39.bed"
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# Define Paths for Sox2CR
SOX2_BAM_DIR="/bgfs/ialdiri/CR/Sox2CR/results/02_alignment/bowtie2/target/dedup"
SOX2_BIGWIG_DIR="/bgfs/ialdiri/CR/Sox2CR/bamCovBW"
SOX2_BAM_FILES=("SOX2_S1_R1.target.dedup.sorted.bam" "SOX2_S3_R1.target.dedup.sorted.bam")

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

# Define paths for SOX2 ATAC Seq (WT and KO)
ATAC_BAM_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_ATAC-Seq/outDir/bowtie2/merged_library"
ATAC_BIGWIG_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_ATAC-Seq/bamCovBW"
# Bam files to process
BAM_FILES=("WT1_REP1.mLb.clN.sorted.bam" "WT2_REP1.mLb.clN.sorted.bam" "KO1_REP1.mLb.clN.sorted.bam" "KO2_REP1.mLb.clN.sorted.bam")

mkdir -p $ATAC_BIGWIG_DIR

# Loop over BAM files to generate bigWig files

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

# Define BW Files

BIGWIG_FILES=("$SOX2_BIGWIG_DIR/SOX2_S1_R1.bigWig" "$ATAC_BIGWIG_DIR/WT1_REP1.bigWig")
PEAKS_DIR="/bgfs/ialdiri/Sox2_ATAC"

# Change reference to center
#  3461 DAR
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  "$PEAKS_DIR/Sox2CR_Sox2WTATAC_int.bed"  \ 
    --binSize $WINDOW_SIZE \
    -o "matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

plotHeatmap -m matrix.gz -out Sox2CR_Sox2WTATAC.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 CR vs WT ATAC" \
    --averageTypeSummaryPlot mean \
    --zMax 25 150 \
    -x "" \
    -z "3461 DARs"\
    --dpi 600 \