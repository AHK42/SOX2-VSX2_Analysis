#!/bin/bash
#SBATCH -t 01:00:00
#SBATCH --job-name=Sup
#SBATCH -c 4
#SBATCH --mem=30g
#SBATCH --output=sup.out

# Load necessary modules
# module purge
# module load gcc/8.2.0
# module load python/anaconda3.10-2022.10
# source activate deeptools

module purge 
# load conda
# shellcheck disable=SC1091 
source /ihome/ialdiri/ahk42/miniconda3/etc/profile.d/conda.sh 
conda activate deeptools_eco

# Define constants
BLACKLIST="/bgfs/ialdiri/Genomes/Mus_musculus/mm10/mm10-blacklist.v2.bed.gz" # mm10 (PLUTO FILES)
CHROM_SIZE="2650000000"
WINDOW_SIZE=10

# Define BAM Paths 

IGG="/bgfs/ialdiri/CR-ChIP/nfcore_runs/CR/Sox2CR_IgG/outDir/02_alignment/bowtie2/target/dedup/IgG_E14.5_R1.target.dedup.sorted.bam"

BW_DIR="/bgfs/ialdiri/Sox2_Vsx2_Original_Analysis/Sox2-VSX2_Analysis/bamCovBW"

mkdir -p $BW_DIR

# # Generate bigWig files for IgG only (previous BWs already generated)
#     bamCoverage \
#         --bam "$IGG" \
#         --outFileName "$BW_DIR/E14.5_IGG_REP1.bigWig" \
#         --binSize $WINDOW_SIZE \
#         --normalizeUsing RPGC \
#         --effectiveGenomeSize $CHROM_SIZE \
#         --ignoreForNormalization chrX \
#         --blackListFileName $BLACKLIST \
#         --numberOfProcessors max \
#         --verbose\
#         --extendReads

# Generate profilePlots for SOX2 

BIGWIG_FILES=("$BW_DIR/SOX2_S1_R1.bigWig" 
			  "$BW_DIR/WT1_REP1.bigWig"
			  "$BW_DIR/E14.5_IGG_REP1.bigWig"
			  "$BW_DIR/SOX2_NB_S2_R1.bigWig"
			  )

SOX2_PEAKS="/bgfs/ialdiri/Sox2_Vsx2_Original_Analysis/Peaks/SOX2_consensus.bed"

# computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
#     -S "${BIGWIG_FILES[@]}" \
#     -R $SOX2_PEAKS \
#     -o "Sup_matrix.gz" \
#     --sortRegions descend \
#     --sortUsing mean \
#     --missingDataAsZero \
#     --verbose -p max --skipZeros --smartLabels

# Sup Figure
plotProfile -m Sup_matrix.gz \
    -out Sup_profile_line.png \
    --plotType lines \
    --dpi 600 \
	--samplesLabel "SOX2" "E14.5 ATAC" "IgG" "Input" \
	--regionsLabel "Sox2 C&R Peaks (3498)"

plotProfile -m Sup_matrix.gz \
    -out Sup_profile_heatmap.png \
    --plotType heatmap \
    --dpi 600 \
    --colors RdBu_r \
    --yMax 20 150 20 20 \
    --regionsLabel "Sox2 C&R Peaks (3498)"

plotHeatmap -m Sup_matrix.gz -out Sup_TornadoPlot.png \
    --colorMap 'Blues' \
    --verbose \
    -T "" \
    -x "" \
	--yMax 25 160 25 25 \
	--zMax 25 160 25 25 \
	--samplesLabel "SOX2" "E14.5 ATAC" "IgG" "Input" \
	--regionsLabel "Sox2 C&R Peaks (3498)" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none

