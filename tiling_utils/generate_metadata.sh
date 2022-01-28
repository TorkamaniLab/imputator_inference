indir=$1

while read line; do

    tiledir=$(echo $line | awk '{print $1}' | tr ':' '_')
    suffix=$(echo $line | awk '{print $2}')
    
    #ls $indir/*$suffix
    model=$(ls best_model_weights/$tiledir/*$suffix/*.pth)
    mname=$(basename $model | sed -e 's/\.pth//g')
    mdir=$(dirname $model)
    echo -e "$suffix\t$mdir\t$mname"

done < tiling_regions/chr22_regions_file.txt > best_model_weights/metadata.tsv

