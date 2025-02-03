#!/bin/bash 

# Load necessary modules
module purge
module load gcc/8.2.0
module load python/anaconda3.10-2022.10
module load rgt/0.12.3
 
# Define Paths
ATAC_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_Stages/ATAC/outDir/bowtie2/merged_library"
OUTPUT_DIR="/bgfs/ialdiri/ATAC-Seq/Sox2_Stages/Motif_Footprinting_P7"
SOX2_PEAKS="/bgfs/ialdiri/ATAC-Seq/Sox2_Stages/ATAC/outDir/bowtie2/merged_library/macs2/narrow_peak/E14.5_REP1.mLb.clN_peaks.narrowPeak"

# Use ATAC files and search for motifs w/ JASPAR database 

#E14.5
rgt-hint footprinting \
    --organism=mm10 \
    --atac-seq --paired-end \
    --output-location="$OUTPUT_DIR/E14.5" \
    --output-prefix=E14.5 \
    "$ATAC_DIR/E14.5_REP1.mLb.clN.sorted.bam" \
    "$SOX2_PEAKS"

# P7
rgt-hint footprinting \
    --organism=mm10 \
    --atac-seq --paired-end \
    --output-location="$OUTPUT_DIR/P7" \
    --output-prefix=P7 \
    "$ATAC_DIR/P7_REP1.mLb.clN.sorted.bam" \
    "$SOX2_PEAKS"

# P21
rgt-hint footprinting \
    --organism=mm10 \
    --atac-seq  --paired-end \
    --output-prefix=P21 \
    --output-location="$OUTPUT_DIR/P21" \
    "$ATAC_DIR/P21_REP1.mLb.clN.sorted.bam" \
    "$SOX2_PEAKS" 

rgt-motifanalysis matching \
    --organism=mm10 \
    --output-location="$OUTPUT_DIR/Motif_Analysis_Vsx2" \
    --input-files "$OUTPUT_DIR/E14.5/E14.5.bed" "$OUTPUT_DIR/P7/P7.bed" "$OUTPUT_DIR/P21/P21.bed" 

rgt-hint differential \
    --organism=mm10 --bc --nc 16 \
    --mpbs-files="$OUTPUT_DIR/Motif_Analysis_Vsx2/E14.5_mpbs.bed","$OUTPUT_DIR/Motif_Analysis_Vsx2/P7_mpbs.bed","$OUTPUT_DIR/Motif_Analysis_Vsx2/P21_mpbs.bed" \
    --reads-files="$ATAC_DIR/E14.5_REP1.mLb.clN.sorted.bam","$ATAC_DIR/P7_REP1.mLb.clN.sorted.bam","$ATAC_DIR/P21_REP1.mLb.clN.sorted.bam" \
    --conditions=E14.5,P7,P21 