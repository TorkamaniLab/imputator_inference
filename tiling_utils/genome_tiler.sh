rdir="$(dirname ${BASH_SOURCE[0]})/../tiling_regions"

chr=$1

input=$2

if [ -z $chr ]; then
   echo "Usage example: bash genome_tiler.sh 22 input_WGS.vcf.gz outdir"
   echo "Usage example2: bash genome_tiler.sh 22 ARIC_chr22_ground_truth_5_phase/c1_ARIC_WGS_Freeze3.lifted_already_GRCh37.GH.ancestry-5.chr22.phased.vcf.gz AFR"
   exit
fi
if [ -z $input ]; then
   echo "Usage example: bash genome_tiler.sh 22 input_WGS.vcf.gz outdir"
   echo "Usage example2: bash genome_tiler.sh 22 ARIC_chr22_ground_truth_5_phase/c1_ARIC_WGS_Freeze3.lifted_already_GRCh37.GH.ancestry-5.chr22.phased.vcf.gz AFR"
   exit
fi

outdir=$3

if [ -z $outdir ]; then
    outdir="."
else
    if [ ! -d $outdir ]; then
        mkdir $outdir
    fi
fi

if [ -f $input ]; then
    if [ ! -f ${input}.tbi ]; then
        echo "tabix -p vcf $input"
        tabix -p vcf $input
    fi
else
    echo "File not found: $input"
    exit
fi

if [ ! -d $outdir ]; then
    mkdir $outdir
fi


echo $outdir/run_${chr}.sh

while read region_line; do

    suffix=$(echo $region_line | cut -f 2 -d ' ')
    region=$(echo $region_line | cut -f 1 -d ' ')
    	
    filename=$(basename $input | sed -e "s/\.vcf\.gz/${suffix}/g" );

    echo $suffix $filename

    echo -e "bcftools view $input -r $region -Ov -o  $outdir/$filename; bgzip -c $outdir/$filename > $outdir/$filename.gz; tabix -p vcf -f $outdir/$filename.gz" >> $outdir/run_${chr}.sh

done < $rdir/chr${chr}_regions_file.txt

chmod +x $outdir/run_${chr}.sh

parallel -j 8 < $outdir/run_${chr}.sh
