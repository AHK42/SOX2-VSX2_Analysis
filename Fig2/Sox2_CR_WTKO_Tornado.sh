#!/bin/bash
#SBATCH -t 04:00:00
#SBATCH --job-name=CR_WTKO
#SBATCH -c 16
#SBATCH --mem=119g
#SBATCH --output=CR_WTKO.out
#SBATCH --error=CR_WTKO.err

module load gcc/8.2.0
module load python/anaconda3.10-2022.10
source activate deeptools

# Define constants/paths
BLACKLIST="/bgfs/ialdiri/Genomes/mm10-blacklist.v2.bed.gz" #! mm10
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# SOX2 Paths
SOX2_BAM_DIR="/bgfs/ialdiri/Pluto_Sox2/Bam"
SOX2_BIGWIG_DIR="/bgfs/ialdiri/Pluto_Sox2/bamCovBW"
SOX2_BAM_FILES=("sample_SOX2_S1_R1.target.dedup.sorted.bam")

mkdir -p $SOX2_BIGWIG_DIR

# Generate bigWig Files
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

# Define Paths 
ATAC_BIGWIG_DIR="/bgfs/ialdiri/Pluto_Sox2/bamCovBW"
PEAKS_DIR="/bgfs/ialdiri/Pluto_Sox2/Peaks" #! CHANGE?

# Define BW File Paths
BIGWIG_FILES=("$SOX2_BIGWIG_DIR/sample_SOX2_S1_R1.bigWig" "$ATAC_BIGWIG_DIR/S2_WT_REP1.bigWig" "$ATAC_BIGWIG_DIR/S6_KO_REP1.bigWig")

# Generate matrix and plots
computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
    -S "${BIGWIG_FILES[@]}" \
    -R  $PEAKS_DIR/CR_DARs_sig_decreased_peaks_overlap.bed  \
    --binSize $WINDOW_SIZE \
    -o "Decreased_CR_matrix.gz" \
    --sortRegions descend \
    --sortUsing mean \
    --missingDataAsZero \
    --verbose -p max --skipZeros --smartLabels

plotHeatmap -m Decreased_CR_matrix.gz -out Sox2_CR_WTKO_ATAC_Decreased.png \
    --colorMap 'Blues' \
    --verbose \
    -T "Sox2 CR vs WT vs KO ATAC" \
    -z "1174 DARs" \
    -x "" \
    --zMax 25 160 160 \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none