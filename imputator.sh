if [ -z $2 ]; then
   echo "Usage example  : ./imputator.sh <input_tiles> <output>"
   echo "Usage example 2: ./imputator.sh input_tiles_chr22 output_chr22"
   exit
fi


indir=$1
outdir=$2

if [ ! -d $outdir ]; then
    mkdir -p $outdir
fi

if [ "${3}" = "GPU" ]; then
    flag="--use_gpu"
fi

while read line; do
    #suffix mdir mname
    suffix=$(echo $line | awk '{print $1}')
    mdir=$(echo $line | awk '{print $2}')
    mname=$(echo $line | awk '{print $3}')
    input=$(ls $indir/*$suffix)
    echo "python3 inference_function.py --model_name $mname $mdir/$mname.pos $indir/*$suffix $mdir --output $outdir $flag"

done < best_model_weights/metadata.tsv > $outdir/run.sh

#parallel -j 8 < $outdir/run.sh

for i in $outdir/*.autoencoder_imputed.vcf; do
    echo "bgzip -c $i > $i.gz; tabix -p vcf $i.gz"
done > $outdir/compress.sh

parallel -j 8 < $outdir/compress.sh

ls $outdir/*.autoencoder_imputed.vcf.gz > $outdir.tiles

bcftools concat -f $outdir.tiles -Ov -o $outdir.vcf

echo "Imputation results in $outdir.vcf"
