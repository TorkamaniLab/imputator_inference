# Imputator: AI-powered imputation of human genomes with pre-trained denoising autoencoders (unphased version)

### This is a demonstration of how to use pre-trained autoencoders for unphased genomic imputation of chromosome 22

The inputs are a VCF file to be imputed (compressed with bgzip and indexed with tabix), and the pre-trained autoencoders (provided here)
The output is an imputed (unphased) VCF file.

## Limitations and restrictions

This version supports only the human chromosome 22 for now. In a future update, this tool will be expanded to whole genome imputation.
This version only supports biallelic variants for now. Multiallelics should be filtered out before running this pipeline.

## Python requirements

- Python v3.6 or later
- torch v1.6 ot later
- Numpy v1.3 or later
- Pandas v1.0 or later

## Other requirements

- bcftools
- tabix
- GNU parallel

## Steps for running the autoencoder-based imputation

The steps are simple: 

1) Downloaded the pretrained model weights; 

2) Tile your input genome (chromosome 22 only in this version);

3) Use the pretrained models to impute your genome tiles and merge the results automatically


That's it! No pre-phasing, no reference panel needed, no access restrictions.


## 1) Download pre-trained model weights

In this step you will download all the pre-trained autoencoders. You have to do this step only once.
You can use wget, curl, or any other download method of your preference.

Here is an example with wget:

```
# download
wget https://www.dropbox.com/s/bicnrx0alkg6a0s/best_model_weights.zip -O best_model_weights.zip
# extract the compressed folder
unzip best_model_weights.zip
```

## 2) Tile your input genome (chromosome 22 only in this version)

The next step is to tile the genomes using our genome tiler tool.
Similar to other imputation tools, we have to tile the genome into parts so we can reduce the computational workload and scale up the imputation process.
For tiling the genome, you run our tiling utility.

```
tiling_utils/tiler.sh <chr> <input_vcf> <output_dir>
```

where: <chr> is the chromosome number (22 only suported for now), <input_vcf> is your input data to be imputed, in VCF.gz format (compressed and tabixed).  

Here is how we tile the example data provided:

```
chmod +x tiling_utils/genome_tiler.sh
tiling_utils/genome_tiler.sh 22 examples/input_chr22.vcf.gz input_tiles_chr22
```

The result should be a directory named input_tiles_chr22, with multiple VMV1 files inside.
Like this:

```
$ ls input_tiles_chr22/ | head
input_chr22.17274081-17382360.vcf.VMV1
input_chr22.17274081-17382360.vcf.VMV1.gz
input_chr22.17274081-17382360.vcf.VMV1.gz.tbi
input_chr22.17365233-17413519.vcf.VMV1
input_chr22.17365233-17413519.vcf.VMV1.gz
input_chr22.17365233-17413519.vcf.VMV1.gz.tbi
input_chr22.17412748-17581941.vcf.VMV1
input_chr22.17412748-17581941.vcf.VMV1.gz
input_chr22.17412748-17581941.vcf.VMV1.gz.tbi
input_chr22.17578285-17676001.vcf.VMV1
```

After you confirm that the command works on the example data, you can replace examples/input_chr22.vcf by your own input vcf file.

## 3) Use the pretrained models to impute your genome tiles and merge the results automatically

The imputator.sh does two jobs: 1) impute all the genome tiles and 2) merge the imputed tiles into a single results

```
chmod +x imputator.sh
./imputator.sh <input_tiles> <output_prefix>
```

Where <input_tiles> is the directory generated in the previous step (e.g. input_tiles_chr22) and <output_prefix> is the name or prefix of the output file (without the .vcf extension)

For example, using the tiles generated for the example file:


```
./imputator.sh input_tiles_chr22 output_chr22
```

The command will generate a folder named output_tiles_chr22 fill of imputed genome tiles in VCF format


If you want to use GPU, just add the "GPU" argument:


```
./imputator.sh input_tiles_chr22 output_chr22 GPU
```

The GPU will only improve speed, the results and accuracy will be the same in CPU and GPU.


Your result will be a fully imputed and merged VCF file. The format of the output is just like a typical VCF. 
Here is a small portion of the output file, just to examplify how the results look like:

```
$ head output_chr22.vcf -n 20 | cut -f 1-10
##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="All filters passed">
##filedate=2022-01-27
##source=Imputation_autoencoder
##contig=<ID=22>
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DS,Number=1,Type=Float,Description="Estimated Alternate Allele Dosage : [P(0/1)+2*P(1/1)]">
##FORMAT=<ID=Paa,Number=1,Type=Float,Description="Imputation probability for homozigous reference : Pa=y_pred[i][j]*(1-y_pred[i][j+1])">
##FORMAT=<ID=Pab,Number=1,Type=Float,Description="Imputation probability for heterozigous : Pab=y_pred[i][j]*y_pred[i][j+1]">
##FORMAT=<ID=Pbb,Number=1,Type=Float,Description="Imputation probability for homozigous alternative : Pb=(1-y_pred[i][j])*y_pred[i][j+1]">
##FORMAT=<ID=AP,Number=1,Type=Float,Description="Predicted presence of reference allele (autoencoder raw output)">
##FORMAT=<ID=BP,Number=1,Type=Float,Description="Predicted presence of alternative allele (autoencoder raw output)">
##bcftools_concatVersion=1.10.2+htslib-1.10.2
##bcftools_concatCommand=concat -f output_chr22.tiles -Ov -o output_chr22.vcf; Date=Thu Jan 27 23:52:19 2022
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  HG00096
22      17274178        .       A       T       .       .       .       GT:DS:Paa:Pab:Pbb:AP:BP 0/0:0.0008:0.9992252363790153:0.0007742868:3.692088856865894e-10
22      17274435        rs4819534       C       T       .       .       .       GT:DS:Paa:Pab:Pbb:AP:BP 0/1:0.5674:0.4441756277433626:0.52198386:0.01828291705763263
22      17274515        rs111837587     G       A       .       .       .       GT:DS:Paa:Pab:Pbb:AP:BP 0/0:0.0024:0.997280010116384:0.0024273908:7.104604548419102e-07
22      17274624        rs73384005      G       A       .       .       .       GT:DS:Paa:Pab:Pbb:AP:BP 0/0:0.0208:0.9778877403643529:0.020731816:2.8658663908665005e-05
22      17274708        rs4819890       G       A       .       .       .       GT:DS:Paa:Pab:Pbb:AP:BP 0/0:0.0384:0.9398927692618231:0.035737634:0.000892665639148138

```

As you can see. The imputation results are exported in variant calling format (VCF) containing the imputed genotypes and imputation quality scores in the form of class probabilities (Paa:Pab:Pbb) for each one of the three possible genotypes (homozygous reference, heterozygous, and homozygous alternate allele). The probabilities can be used for quality control of the imputation results. 

The output nodes of the autoencoder (AP, BP) range between 0 and 1, and are also split into three genotype classes (homozygous reference = Paa, alternate = Pbb, and heterozygous = Pab).
Paa, Pab, Pbb are probabilities normalized using the Softmax function. The normalized outputs can also be regarded as a measure of imputation quality.


## Reference
Dias R, Evans D, Chen SF, Chen KY, Chan L, Torkamani A. Rapid, Reference-Free Human Genotype Imputation with Denoising Autoencoders. 2022. In press.


