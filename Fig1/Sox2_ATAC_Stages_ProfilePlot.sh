#!/bin/bash 
#SBATCH -t 04:00:00
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


# Define constants  
BLACKLIST="/bgfs/ialdiri/Genomes/mm10-blacklist.v2.liftover.mm39.bed" # mm39
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# Define paths for SOX2 ATAC Stages
STAGES_BAM_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_Stages/ATAC/outDir/bowtie2/merged_library"
STAGES_BIGWIG_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_Stages/ATAC/bamCovBW"
# Bam files to process
BAM_FILES=("E14.5_REP1.mLb.clN.sorted.bam" "P7_REP1.mLb.clN.sorted.bam" "P21_REP1.mLb.clN.sorted.bam")

mkdir -p $STAGES_BIGWIG_DIR

# Generate bigWig Files

for BAM in "${BAM_FILES[@]}"; do
    SAMPLE_NAME=$(basename "$BAM" | awk -F".mLb" '{print $1}')
    bamCoverage \
        --bam "$STAGES_BAM_DIR/$BAM" \
        --outFileName "$STAGES_BIGWIG_DIR/${SAMPLE_NAME}.bigWig" \
        --binSize $WINDOW_SIZE \
        --normalizeUsing RPGC \
        --effectiveGenomeSize $CHROM_SIZE \
        --ignoreForNormalization chrX \
        --blackListFileName $BLACKLIST \
        --numberOfProcessors max \
        --verbose 
done

BIGWIG_FILES=("$STAGES_BIGWIG_DIR/E14.5_REP1.bigWig" "$STAGES_BIGWIG_DIR/P7_REP1.bigWig" "$STAGES_BIGWIG_DIR/P21_REP1.bigWig")
PEAKS_DIR="/bgfs/ialdiri/Sox2_ATAC/Peaks"

computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R "$PEAKS_DIR/Sox2CR_E14.5_WT_ATAC_int.bed" \
    --binSize $WINDOW_SIZE \
    -o "profile_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

# Plot median instead of mean 
plotProfile -m profile_matrix.gz -out Sox2_ATAC_Stages_profilePlot_median.png \
    --verbose \
    -T "Sox2 ATAC Stages" \
    --dpi 600 \
    --perGroup \
    -z "3412 Peaks" \
    --averageType median