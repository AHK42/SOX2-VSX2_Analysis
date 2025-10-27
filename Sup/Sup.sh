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

# IGG="/bgfs/ialdiri/CR-ChIP/nfcore_runs/CR/Sox2CR_IgG/outDir/02_alignment/bowtie2/target/dedup/IgG_E14.5_R2.target.dedup.sorted.bam"
# CHIP="/bgfs/ialdiri/CR-ChIP/nfcore_runs/ChIP/SOX2-PAX6_ChIP/outDir/bowtie2/mergedLibrary/SOX2.mLb.clN.sorted.bam"
CHIP_INPUT="/bgfs/ialdiri/CR-ChIP/nfcore_runs/ChIP/SOX2-PAX6_ChIP/outDir/bowtie2/mergedLibrary/Input.mLb.clN.sorted.bam"

BW_DIR="/bgfs/ialdiri/Sox2_Vsx2_Original_Analysis/Sox2-VSX2_Analysis/bamCovBW"

mkdir -p $BW_DIR

# # Generate bigWig files for IgG only (previous BWs already generated)
#     bamCoverage \
#         --bam "$CHIP_INPUT" \
#         --outFileName "$BW_DIR/SOX2_ChIP_Input.bigWig" \
#         --binSize $WINDOW_SIZE \
#         --normalizeUsing RPGC \
#         --effectiveGenomeSize $CHROM_SIZE \
#         --ignoreForNormalization chrX \
#         --blackListFileName $BLACKLIST \
#         --numberOfProcessors max \
#         --verbose\
#         # --extendReads

# Generate profilePlots for SOX2 

BIGWIG_FILES=("$BW_DIR/SOX2_S1_R1.bigWig" 
			  # "$BW_DIR/WT1_REP1.bigWig"
			  # "$BW_DIR/E14.5_IGG_REP2.bigWig"
			  # "$BW_DIR/SOX2_NB_S2_R1.bigWig"
			  "$BW_DIR/SOX2_ChIP.bigWig"
			  "$BW_DIR/SOX2_ChIP_Input.bigWig"
			  )

SOX2_PEAKS="/bgfs/ialdiri/Sox2_Vsx2_Original_Analysis/Peaks/SOX2_consensus.bed"

# computeMatrix reference-point --referencePoint center -b 2000 -a 2000 \
#     -S "${BIGWIG_FILES[@]}" \
#     -R $SOX2_PEAKS \
#     -o "Sox2_cor_matrix.gz" \
#     --sortRegions descend \
#     --sortUsing mean \
#     --missingDataAsZero \
#     --verbose -p max --skipZeros --smartLabels


# plotHeatmap -m Sup_matrix.gz -out Sup_TornadoPlot.png \
#     --colorMap 'Blues' \
#     --verbose \
#     -T "" \
#     -x "" \
# 	--yMax 25 160 25 25 \
# 	--zMax 25 160 25 25 \
# 	--samplesLabel "SOX2" "ATAC" "IgG" "Input" \
# 	--regionsLabel "Sox2 C&R Peaks (3498)" \
#     --averageTypeSummaryPlot mean \
#     --dpi 600 --legendLocation none

plotHeatmap -m Sox2_cor_matrix.gz -out Sox2_cor_TornadoPlot.png \
    --colorMap 'Blues' \
    --verbose \
    -T "" \
    -x "" \
	--samplesLabel "SOX2 C&R" "SOX2 ChIP" "ChIP Input" \
	--regionsLabel "Sox2 C&R Peaks (3498)" \
    --averageTypeSummaryPlot mean \
    --dpi 600 --legendLocation none 

plotProfile -m Sox2_cor_matrix.gz \
    -out Sox2_cor_profilePlot.png \
    --plotType lines \
    --dpi 600 \
	--samplesLabel "SOX2 C&R" "SOX2 ChIP" "ChIP Input" \
	--regionsLabel "Sox2 C&R Peaks (3498)" \
	--perGroup

plotProfile -m Sox2_cor_matrix.gz \
    -out Sox2_cor_Heatmap.png \
    --plotType heatmap \
    --dpi 600 \
    --colors RdBu_r \
	--samplesLabel "SOX2 C&R" "SOX2 ChIP" "ChIP Input" \
    --regionsLabel "Sox2 C&R Peaks (3498)" \
	--perGroup



