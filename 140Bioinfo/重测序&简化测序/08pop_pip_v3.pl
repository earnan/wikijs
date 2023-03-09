#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use YAML::Tiny ;
use File::Basename qw(basename dirname);
use Pipeliner ;
use threads ;
use Config::General;
use Cwd qw(abs_path getcwd);
my $BEGIN_TIME=time();
my $version="1.0.0";
##---------------------------------------------------------------------------------------------
my ($infile,$outdir);
my $have_chr;

GetOptions(
				"help|?" =>\&USAGE,
				"i:s"=>\$infile,
				"c:s"=>\$have_chr,
				"o:s"=>\$outdir,
				) or &USAGE;
&USAGE unless ($infile and $outdir and defined $have_chr);
##----------------------------------------------------------------------------------------------

# Main Body
##----------------------------------------------------------------------------------------------
mkdir $outdir unless (-d $outdir);
$outdir=abs_path($outdir);
$infile=abs_path($infile);

my $cmds_dir="$outdir/.cmds_dir";
mkdir $cmds_dir unless (-d "$cmds_dir") ;
my $flag_dir="$outdir/.flag_dir";
mkdir $flag_dir unless (-d "$flag_dir") ;



#  1.整齐
print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Software -------------------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
my $VERBOSE=0;
my $ParaFly="$Bin/script/ParaFly";
my $main=YAML::Tiny::LoadFile($infile);
#software
my %config=&readConfig("$Bin/script/Config/CFG"); # /share/nas6/zhouxy/pipline/genetic_diversity_pip/v1.0/script/Config/CFG
my $Rscript=$config{"Rscript"};
my $perl=$config{"perl"};
my $python=$config{"python"};
my $samtools=$config{"samtools"};
my $ngsqc=$config{"ngsqc"};
my $depth_stat_windows=$config{"depth_stat_windows"};
my $bcftools=$config{"bcftools"};
my $java=$config{"java"};
my $python3=$config{"python3"};
my $gatk=$config{"gatk"};
my $bwa=$config{"bwa"};
my $plink=$config{"plink"};   # 对应 plink	/share/nas6/zhouxy/biosoft/plink/v20200428/plink
my $PopLDdecay=$config{"PopLDdecay"};
my $primer3_core=$config{"primer3_core"};
my $gcta=$config{"gcta"};
my $FastTreeMP=$config{"FastTreeMP"};

#file
my $chrlist = $main->{Project}{Genome}{chr};


print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 00 : config information -----------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/config_dir") ;

#print Dumper $main;
my @samples=sort {$a cmp $b} keys %{$main->{"Project"}{"Samples"}};
my @groups=sort {$a cmp $b} keys %{$main->{"Project"}{"Groups"}};
my $groupnum=@groups;
my $samplenum=@samples;
my @read1files;
my @read2files;

open (OUT,">","$outdir/config_dir/samples_info.txt") or die $!;
for (my $i=0;$i<@samples;$i++) {
	my $read1file=basename($main->{"Project"}{"Samples"}{$samples[$i]}{"read1"});
	my $read2file=basename($main->{"Project"}{"Samples"}{$samples[$i]}{"read2"});
	print OUT $samples[$i],"\t",$read1file,"\t",$read2file,"\n";
	push @read1files,$read1file;
	push @read2files,$read2file;
}
close (OUT) ;
my $read1_string=join(",",@read1files);
my $read2_string=join(",",@read2files);
my $cmd ="";

my %mapgroup;

open (DATA1,">","$outdir/config_dir/samples.list") or die $!;
open (DATA2,">","$outdir/config_dir/group.list") or die $!;
open (DATA3,">","$outdir/config_dir/group.txt") or die $!;

for (my $i=0;$i<@groups;$i++) {
	my @strings=split /,/,$main->{"Project"}{"Groups"}{$groups[$i]};
	map {$mapgroup{$_}=$groups[$i]} @strings;
	map {print DATA2 $_,"\t",$groups[$i],"\n"} @strings;
	print DATA1 join("\n",sort {$a cmp $b} @strings),"\n";
	print DATA3 $groups[$i],"\n";

	open (GG,">","$outdir/config_dir/$groups[$i].list") or die $!;
	print GG join("\n",@strings),"\n";
}
close (DATA1) ;
close (DATA2) ;
close (DATA3) ;
close (GG) ;



open (OUT,">","$outdir/config_dir/population.list") or die $!;
foreach my $sample (sort {$a cmp $b} keys %mapgroup ) {
	print OUT $mapgroup{$sample},"\t",$sample,"\n";
}
close (OUT) ;


Mkdir("$outdir/genome") ;
my $genome_name=basename($main->{Project}{Genome}{seq});

my $t1 = threads -> new(\&fastQC);
my $t2 = threads -> new(\&genomeQC,$genome_name);
my $t3 = threads -> new(\&IndexBuild);

$t1 -> join();
$t2 -> join();
$t3 -> join();


sub fastQC {#
	print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                       ."--------------------- Step 01 : fastQC -----------------------------------------\n"
                       ."--------------------------------------------------------------------------------\n\n\n";
	mkdir "$outdir/fastqc_dir" unless (-d "$outdir/fastqc_dir") ;
	open (CMD1,">","$cmds_dir/fastQC.cmds") or die $!;
	open (CMD2,">","$cmds_dir/fastQC_plot.cmds") or die $!;
	for (my $i=0;$i<@samples;$i++) {
		my $read1file=$main->{"Project"}{"Samples"}{$samples[$i]}{"read1"};
		my $read2file=$main->{"Project"}{"Samples"}{$samples[$i]}{"read2"};

		my $cmd1 = " $ngsqc -1 $read1file -2 $read2file -k $samples[$i] -o $outdir/fastqc_dir ";
		my $cmd2 = " $Rscript $Bin/script/00qc/ngsqc.R --base $outdir/fastqc_dir/$samples[$i].atgc "
					. " --qual $outdir/fastqc_dir/$samples[$i].qual --out $outdir/fastqc_dir/$samples[$i] ";

		print CMD1 $cmd1,"\n";
		print CMD2 $cmd2,"\n";
	}
	my $cmd3 = "$python $Bin/script/00qc/ngsqc_stat.py -i $outdir/fastqc_dir -o $outdir/fastqc_dir/samples.stat.xls";
	print CMD2 $cmd3,"\n";
	close (CMD1) ;
	close (CMD2) ;
	Pipline_qsub_commands("fastQC.cmds","fastQC.ok",50);
	Pipline_sh_commands("fastQC_plot.cmds","fastQC_plot.ok");
}



sub IndexBuild {#
	print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                      ."--------------------- Step 02 : Reference Index Build --------------------------\n"
                      ."--------------------------------------------------------------------------------\n\n\n";
	open (CMD,">","$cmds_dir/bwa_index.cmds") or die $!;
	{
		my $cmd1 = " ln -sf $main->{Project}{Genome}{seq} $outdir/genome/$genome_name "
			. " && $bwa index $outdir/genome/$genome_name "
			. " && grep -v '^#' -P $main->{Project}{Genome}{gff} > $outdir/genome/genome.gff ";
		print CMD $cmd1,"\n";
	}
	close (CMD) ;
	Pipline_sh_commands("bwa_index.cmds","reference_index_build.ok");
}


sub genomeQC {#
	my ($genome_name)=@_;
	my $genome_dict=$genome_name; 
	$genome_dict=~s/fasta|fa|fna/dict/;
	open (CMD,">","$cmds_dir/genome_stat.cmds") or die $!;
	{
		print CMD " $perl $Bin/script/00qc/ref_GC_len.pl -ref $outdir/genome/$genome_name -od $outdir/genome\n";
		print CMD " $samtools dict $outdir/genome/$genome_name > $outdir/genome/$genome_dict\n";
		print CMD " $samtools faidx $outdir/genome/$genome_name\n";
		print CMD " $perl $Bin/script/02variant/chr2splitbed.pl -i $outdir/genome/$genome_name.fai -o $outdir/genome/bedinfo";
	}
	close (CMD) ;
	Pipline_sh_commands("genome_stat.cmds","genome_GC_csd.ok");
}



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 03 : BWA Alignment ----------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/mapping_dir") ;
Mkdir("$outdir/mapping_dir/01.bwa2sortbam") ;

open (CMD1,">","$cmds_dir/bwa2sortbam_align.cmds") or die $!;
open (CMD2,">","$cmds_dir/samtools_index.cmds") or die $!;

my (@gatkbams);
for (my $i=0;$i<@samples;$i++) {
	my $cmd1 = " $bwa mem -M -t 5 -R "."'".'@RG\tID:'.$samples[$i].'\tLB:'.$samples[$i].'\tPL:ILLUMINA\tSM:'.$samples[$i]."' $outdir/genome/$genome_name "
				. " $main->{Project}{Samples}{$samples[$i]}{read1} $main->{Project}{Samples}{$samples[$i]}{read2} "
				. " | $samtools sort -O bam -@ 4 -m 1G -T $outdir/mapping_dir/01.bwa2sortbam/$samples[$i] "
				. " -o $outdir/mapping_dir/01.bwa2sortbam/$samples[$i].sort.bam - ";

	my $cmd2 = " $samtools index $outdir/mapping_dir/01.bwa2sortbam/$samples[$i].sort.bam ";
	push @gatkbams,"$outdir/mapping_dir/01.bwa2sortbam/$samples[$i].sort.bam";
	print CMD1 $cmd1,"\n";
	print CMD2 $cmd2,"\n";
}
close (CMD1) ;
close (CMD2) ;
Pipline_qsub_commands("bwa2sortbam_align.cmds","bwa2sortbam_align.ok",30);
Pipline_qsub_commands("samtools_index.cmds","samtools_index.ok",30);



print STDERR "\n\n\n--------------------------------------------------------------------------\n"
                  ."--------------------- Step 04 : BAM statistics  --------------------------\n"
                  ."--------------------------------------------------------------------------\n\n\n";
my $t4 = threads -> new(\&BamStat);
$t4 -> join();

sub BamStat {#
	Mkdir("$outdir/mapping_dir/mapping_depth") ;
	Mkdir("$outdir/mapping_dir/mapping_stat") ;
	Mkdir("$outdir/mapping_dir/mapping_stat/bcparse") ;
	Mkdir("$outdir/mapping_dir/mapping_stat/bcfiles") ;

	open (CMD1,">","$cmds_dir/bam2bc_stat.cmds") or die $!;
	open (CMD2,">","$cmds_dir/bam2depth.cmds") or die $!;
	open (CMD3,">","$cmds_dir/depth2windows.cmds") or die $!;
	open (CMD4,">","$cmds_dir/genomeCoveragehorizontalArea.cmds") or die $!;
#	open (OUT,">","$cmds_dir/chr2convert.cmds") or die $!;
	for (my $i=0;$i<@samples;$i++) {
		print CMD1 " $samtools stats $outdir/mapping_dir/01.bwa2sortbam/$samples[$i].sort.bam "
				. " > $outdir/mapping_dir/mapping_stat/bcfiles/$samples[$i].bc \n";

		print CMD2 " $samtools depth $outdir/mapping_dir/01.bwa2sortbam/$samples[$i].sort.bam "
				. " > $outdir/mapping_dir/mapping_depth/$samples[$i].depth\n";

		print CMD3 " $depth_stat_windows -i $outdir/mapping_dir/mapping_depth/$samples[$i].depth "
					. " -o $outdir/mapping_dir/mapping_depth/$samples[$i].depth.fordraw -w 50000 \n";

	#	print OUT " python3 $Bin/script/bam_stat/chr2convert.py -i $outdir/mapping_dir/mapping_depth/$samples[$i].depth.fordraw "
	#				. " -c $main->{Project}{Genome}{chr2convert} -o $outdir/mapping_dir/mapping_depth/$samples[$i].depth.fordraw.bak \n";

		print CMD4 " $Rscript $Bin/script/01bam/genomeCoveragehorizontalArea.R --infile $outdir/mapping_dir/mapping_depth/$samples[$i].depth.fordraw "
				. " --idfile $main->{Project}{Genome}{chr} --outfile $outdir/mapping_dir/mapping_depth/$samples[$i].genome.coverage "
				. " --group.col 1 --x.col 2 --y.col 3 --x.lab Sequence-Position --y.lab AverageDepth-log2 --skip 0 --unit 100kb --log2 \n";
	}
	close (CMD1) ;
	close (CMD2) ;
	close (CMD3) ;
	close (CMD4) ;

	open (CMD,">","$cmds_dir/bcparse.cmds") or die $!;
	print CMD " $perl $Bin/script/01bam/samtools_stats_parser2.pl -i $outdir/mapping_dir/mapping_stat/bcfiles "
			. " -o $outdir/mapping_dir/mapping_stat/bcparse -r $outdir/genome/$genome_name \n";
	close (CMD) ;

	Pipline_qsub_commands("bam2bc_stat.cmds","bam2bc_stat.ok",50);
	Pipline_qsub_commands("bam2depth.cmds","bam2depth.ok",50);
	Pipline_qsub_commands("depth2windows.cmds","depth2windows.ok",50);
	Pipline_qsub_commands("genomeCoveragehorizontalArea.cmds","genomeCoveragehorizontalArea.ok",50);
	Pipline_sh_commands("bcparse.cmds","bcparse.ok");
}



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 5.1 : gatk HaplotypeCaller --------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/variation_dir") ;
Mkdir("$outdir/variation_dir/HaplotypeCaller") ;
Mkdir("$outdir/variation_dir/tmp") ;
my $fbamfiles_str = join(" -I ",@gatkbams);
my @gvcffiles ;

open (CMD,">", "$cmds_dir/gatk_HaplotypeCaller.cmds") or die $!;
{
	my @bedfiles=glob "$outdir/genome/bedinfo/*.bed";
	foreach my $sample (@samples) {
		push @gvcffiles,"$outdir/variation_dir/HaplotypeCaller/$sample.gatk.raw.g.vcf.gz";

		my $cmd1= " $gatk --java-options \"-Xmx4g\" HaplotypeCaller -R $outdir/genome/$genome_name "
					. " -I $outdir/mapping_dir/01.bwa2sortbam/$sample.sort.bam "
					. " -O $outdir/variation_dir/HaplotypeCaller/$sample.gatk.raw.g.vcf.gz "
					. " --emit-ref-confidence GVCF -stand-call-conf 30.0 --min-base-quality-score 10 "
					. " --dont-use-soft-clipped-bases true "
					. " --tmp-dir $outdir/variation_dir/tmp ";
		print CMD $cmd1,"\n";
	}

#	foreach my $bedfile (@bedfiles) {
#		my ($chr)=basename($bedfile)=~/(.*?)\.bed/;
#		my $cmd1= " gatk --java-options \"-Xmx4g\" HaplotypeCaller -R $outdir/genome/$genome_name "
#					. " -I $fbamfiles_str "
#					. " -O $outdir/variation_dir/HaplotypeCaller/samples.$chr.gatk.raw.vcf.gz "
#					. " -stand-call-conf 30.0 --min-base-quality-score 10 "
#					. " --dont-use-soft-clipped-bases true -L $bedfile "
#					. " --tmp-dir $outdir/variation_dir/tmp ";
#		print CMD $cmd1,"\n";
#		push @gvcffiles,"$outdir/variation_dir/HaplotypeCaller/samples.$chr.gatk.raw.vcf.gz";
#	}

}
close (CMD) ;
Pipline_qsub_commands("gatk_HaplotypeCaller.cmds","gatk_HaplotypeCaller.ok",80);




print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 5.2 : gatk CombineGVCFs and GenotypeGVCFs -----------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/variation_dir/CombineGVCFs") ;
Mkdir("$outdir/variation_dir/GenotypeGVCFs") ;

open (CMD1,">","$cmds_dir/gatk_CombineGVCFs.cmds") or die $!;
open (CMD2,">","$cmds_dir/gatk_GenotypeGVCFs.cmds") or die $!;
my $gvcf_str=join " -V ",@gvcffiles;
my @GatherVCFs;
{
	my @bedfiles=glob "$outdir/genome/bedinfo/*.bed";
	for (my $i=0;$i<@bedfiles ;$i++) {
		my ($chr)=basename($bedfiles[$i])=~/(.*?)\.bed/;
		my $cmd1 = " $gatk CombineGVCFs -R $outdir/genome/$genome_name -V $gvcf_str "
					. " -O $outdir/variation_dir/CombineGVCFs/samples.$chr.g.vcf.gz -L $bedfiles[$i] "
					. " --tmp-dir $outdir/variation_dir/tmp ";
		print CMD1 $cmd1,"\n";

		my $cmd2 = " $gatk GenotypeGVCFs -R $outdir/genome/$genome_name "
					. " -V $outdir/variation_dir/CombineGVCFs/samples.$chr.g.vcf.gz "
					. " -O $outdir/variation_dir/GenotypeGVCFs/samples.$chr.raw.vcf.gz "
					. " --tmp-dir $outdir/variation_dir/tmp ";
		print CMD2 $cmd2,"\n";
		push @GatherVCFs,"$outdir/variation_dir/GenotypeGVCFs/samples.$chr.raw.vcf.gz";
	}
	close (CMD1) ;
	close (CMD2) ;
}
Pipline_qsub_commands("gatk_CombineGVCFs.cmds","gatk_CombineGVCFs.ok",50);
Pipline_qsub_commands("gatk_GenotypeGVCFs.cmds","gatk_GenotypeGVCFs.ok",50);



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 5.3 : gatk4 GatherVCFs ------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";

my @Allchrs;
open (IN,"$outdir/genome/$genome_name.fai") or die $!;
while (<IN>) {
	chomp;
	my ($chr)=split /\t/;
	push @Allchrs,$chr;
}
close (IN) ;


open (CMD,">","$cmds_dir/gatk_GatherVCFs.cmds") or die $!;
Mkdir("$outdir/variation_dir/GatherVCFs") ;
{
	my $GatherVcfs_str=join(" -I ",sort {(split /\./,basename($a))[1]<=>(split /\./,basename($b))[1]} @GatherVCFs);
	my $cmd1 = " $gatk GatherVcfs -I $GatherVcfs_str -O $outdir/variation_dir/GatherVCFs/samples.gatk.raw.vcf.gz "
				. " --TMP_DIR $outdir/variation_dir/tmp "
				. " && $gatk IndexFeatureFile -I $outdir/variation_dir/GatherVCFs/samples.gatk.raw.vcf.gz ";
	print CMD $cmd1,"\n";
	close (CMD) ;
}
Pipline_sh_commands("gatk_GatherVCFs.cmds","gatk_GatherVCFs.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 5.4 : gatk SelectVariants ---------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/variation_dir/variants_vqsr_dir") ;
open (CMD,">","$cmds_dir/gatk_SelectVariants.cmds") or die $!;
{
	my $cmd1 = " $gatk --java-options \"-Xmx4g\" SelectVariants "
			. " -R $outdir/genome/$genome_name "
			. " -V $outdir/variation_dir/GatherVCFs/samples.gatk.raw.vcf.gz "
			. " --select-type-to-include SNP --exclude-non-variants "
			. " -O $outdir/variation_dir/GatherVCFs/samples.gatk.con.snp.vcf.gz ";
	my $cmd2 = " $gatk --java-options \"-Xmx4g\" SelectVariants "
			. " -R $outdir/genome/$genome_name "
			. " -V $outdir/variation_dir/GatherVCFs/samples.gatk.raw.vcf.gz "
			. " --select-type-to-include INDEL --exclude-non-variants "
			. " -O $outdir/variation_dir/GatherVCFs/samples.gatk.con.indel.vcf.gz ";
	
	print CMD $cmd1,"\n",$cmd2,"\n";
}
close (CMD) ;
Pipline_parafly_commands("gatk_SelectVariants.cmds","gatk_SelectVariants.ok","gatk_SelectVariants.failed.cmds",10);



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 5.5 : gatk VariantRecalibrator ----------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
open (CMD,">","$cmds_dir/gatk_VQSR.cmds") or die $!;
{
	#https://gatk.broadinstitute.org/hc/en-us/articles/360035531112--How-to-Filter-variants-either-with-VQSR-or-by-hard-filtering
	my $cmd1 = " $gatk --java-options \"-Xmx4g -Xms4g\" VariantRecalibrator "
		. " -R $outdir/genome/$genome_name "
		. " -V $outdir/variation_dir/GatherVCFs/samples.gatk.con.snp.vcf.gz "
		. " -O $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.recal "
		. " --tranches-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.tranches"
		. " --rscript-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.plots.R "
		. " -mode SNP -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum "#-an MQ 
		. " --resource:hapmap,known=false,training=true,truth=true,prior=10.0 "
		. " $outdir/variation_dir/GatherVCFs/samples.gatk.con.snp.vcf.gz "
		. " -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 97.0 -tranche 95.0 -tranche 93.0 -tranche 90.0 "
		. " --max-gaussians 6 --minimum-bad-variants 1000 --bad-lod-score-cutoff -5 "
		. " --tmp-dir $outdir/variation_dir/tmp ";

	my $cmd2 = " $gatk ApplyVQSR -mode SNP "
		. " --truth-sensitivity-filter-level 99 "
		. " -R $outdir/genome/$genome_name "
		. " -V $outdir/variation_dir/GatherVCFs/samples.gatk.con.snp.vcf.gz "
		. " --recal-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.recal "
		. " --tranches-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.tranches "
		. " -O $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.vqsr.vcf.gz " 
		. " --tmp-dir $outdir/variation_dir/tmp ";
	print CMD $cmd1," && ",$cmd2,"\n";

	my $cmd3 = " $gatk --java-options \"-Xmx4g -Xms4g\" VariantRecalibrator "
		. " -R $outdir/genome/$genome_name "
		. " -V $outdir/variation_dir/GatherVCFs/samples.gatk.con.indel.vcf.gz "
		. " -O $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.recal "
		. " --tranches-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.tranches"
		. " --rscript-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.plots.R "
		. " -mode INDEL -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum "#-an MQ 
		. " --resource:hapmap,known=false,training=true,truth=true,prior=10.0"
		. " $outdir/variation_dir/GatherVCFs/samples.gatk.con.indel.vcf.gz "
		. " -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 97.0 -tranche 95.0 -tranche 93.0 -tranche 90.0 "
		. " --max-gaussians 6 --minimum-bad-variants 1000 --bad-lod-score-cutoff -5 "
		. " --tmp-dir $outdir/variation_dir/tmp ";

	my $cmd4 = " $gatk ApplyVQSR -mode INDEL "
		. " --truth-sensitivity-filter-level 99 "
		. " -R $outdir/genome/$genome_name "
		. " -V $outdir/variation_dir/GatherVCFs/samples.gatk.con.indel.vcf.gz "
		. " --recal-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.recal "
		. " --tranches-file $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.tranches "
		. " -O $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.vqsr.vcf.gz "
		. " --tmp-dir $outdir/variation_dir/tmp ";
	print CMD $cmd3," && ",$cmd4,"\n";
	close (CMD) ;
}
Pipline_parafly_commands("gatk_VQSR.cmds","gatk_VQSR.ok","gatk_VQSR.failed.cmds",10);



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 5.6 : gatk VariantFiltration ------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	open (CMD,">","$cmds_dir/gatk_VariantFiltration.cmds") or die $!;
	my $cmd1 = " $gatk VariantFiltration -R $outdir/genome/$genome_name "
				. " -V $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.vqsr.vcf.gz "
				. ' --filter-expression "QD < 2.0" --filter-name "QD2" '
				. ' --filter-expression "MQ < 40.0" --filter-name "MQ40" '
				. ' --filter-expression "FS > 60.0" --filter-name "FS60" '
				. ' --filter-expression "SOR > 6.0" --filter-name "SOR6" '
				. ' --filter-expression "QUAL < 30.0" --filter-name "QUAL30" '
				. ' --filter-expression "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" '
				. ' --filter-expression "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" '
#				. ' -clusterSize 2 -clusterWindowSize 5 '
				. " -O $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.vqsr.filter.vcf.gz "
				. " --tmp-dir $outdir/variation_dir/tmp ";
	my $cmd2 = " $gatk VariantFiltration -R $outdir/genome/$genome_name "
				. " -V $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.vqsr.vcf.gz "
				. ' --filter-expression "QD < 2.0" --filter-name "QD2" '
				. ' --filter-expression "MQ < 40.0" --filter-name "MQ40" '
				. ' --filter-expression "FS > 60.0" --filter-name "FS60" '
				. ' --filter-expression "SOR > 6.0" --filter-name "SOR6" '
				. ' --filter-expression "QUAL < 30.0" --filter-name "QUAL30" '
				. ' --filter-expression "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" '
				. ' --filter-expression "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" '
#				. ' -clusterSize 2 -clusterWindowSize 5 '
				. " -O $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.vqsr.filter.vcf.gz "
				. " --tmp-dir $outdir/variation_dir/tmp ";
	print CMD $cmd1,"\n",$cmd2,"\n";
	close (CMD) ;
}
Pipline_parafly_commands("gatk_VariantFiltration.cmds","gatk_VariantFiltration.ok","gatk_VariantFiltration.failed.cmds",10);



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 5.7 : gatk Filter -----------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
open (CMD,">","$cmds_dir/gatk_FilterInfo.cmds") or die $!;
Mkdir("$outdir/variation_dir/variants_anno_dir") ;
{
	my $cmd1 = " $perl $Bin/script/03vcf/format_filter.pl -i "
			. " $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.snp.vqsr.filter.vcf.gz "
			. " -o $outdir/variation_dir/variants_anno_dir/samples.gatk.con.snp.vqsr.filter.vcf ";

	my $cmd2 = " $perl $Bin/script/03vcf/format_filter.pl -i "
			. " $outdir/variation_dir/variants_vqsr_dir/samples.gatk.con.indel.vqsr.filter.vcf.gz "
			. " -o $outdir/variation_dir/variants_anno_dir/samples.gatk.con.indel.vqsr.filter.vcf ";
	print CMD $cmd1,"\n",$cmd2,"\n";
}
close (CMD) ;
Pipline_sh_commands("gatk_FilterInfo.cmds","gatk_FilterInfo.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 6.1 : SnpEff build index ----------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
open (CMD,">","$cmds_dir/snpeff_index.cmds") or die $!;
{
	$cmd = " $perl $Bin/script/04snpeff/snpeff_build.pl -g $outdir/genome/$genome_name -gff $outdir/genome/genome.gff "
			. " -o $outdir/variation_dir/snpeff_index -k $main->{Project}{Programs}{SNPEFF}{dbname} ";
	print CMD $cmd,"\n";
}
close (CMD) ;
Pipline_sh_commands("snpeff_index.cmds","snpeff_index.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 6.2 : GATK Annotation ------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/variation_dir/variants_anno_dir") ;

open (CMD,">","$cmds_dir/Variant_Annotation.cmds") or die $!;
{
	my $SNPEFF_JAR='/share/nas6/zhouxy/biosoft/snpEff/current/snpEff.jar';
	my $cmd1 = " $java -jar $SNPEFF_JAR $main->{Project}{Programs}{SNPEFF}{dbname} -o gatk "
			 . " -csvStats $outdir/variation_dir/variants_anno_dir/samples.snp.stat.csv "
			 . " -htmlStats $outdir/variation_dir/variants_anno_dir/samples.snp.stat.html "
			 . " -c $outdir/variation_dir/snpeff_index/$main->{Project}{Programs}{SNPEFF}{dbname}.config "
			 . " -v $outdir/variation_dir/variants_anno_dir/samples.gatk.con.snp.vqsr.filter.vcf "
			 . " > $outdir/variation_dir/variants_anno_dir/samples.gatk.con.snp.vqsr.filter.anno.vcf ";

	my $cmd2 = " $perl $Bin/script/02variant/extract_oneEff_anno.pl -i $outdir/variation_dir/variants_anno_dir/samples.gatk.con.snp.vqsr.filter.anno.vcf "
			 . " -o $outdir/variation_dir/variants_anno_dir/samples.pop.snp.anno.result.vcf " ;

	my $cmd3 = " $perl $Bin/script/02variant/vcf_to_snplist_v1.5.pl -i $outdir/variation_dir/variants_anno_dir/samples.pop.snp.anno.result.vcf "
			. " -o $outdir/variation_dir/variants_anno_dir/samples.pop.snp.anno.result.list -ref 1 ";

	print CMD $cmd1,"\n",$cmd2,"\n",$cmd3,"\n";

	my $cmd4 = " $java -jar $SNPEFF_JAR $main->{Project}{Programs}{SNPEFF}{dbname} -o gatk "
			 . " -csvStats $outdir/variation_dir/variants_anno_dir/samples.indel.stat.csv "
			 . " -htmlStats $outdir/variation_dir/variants_anno_dir/samples.indel.stat.html "
			 . " -c $outdir/variation_dir/snpeff_index/$main->{Project}{Programs}{SNPEFF}{dbname}.config "
			 . " -v $outdir/variation_dir/variants_anno_dir/samples.gatk.con.indel.vqsr.filter.vcf "
			 . " > $outdir/variation_dir/variants_anno_dir/samples.gatk.con.indel.vqsr.filter.anno.vcf ";

	my $cmd5 = " $perl $Bin/script/02variant/extract_oneEff_anno.pl -i $outdir/variation_dir/variants_anno_dir/samples.gatk.con.indel.vqsr.filter.anno.vcf "
			 . " -o $outdir/variation_dir/variants_anno_dir/samples.pop.indel.anno.result.vcf " ;

	my $cmd6 = " $perl $Bin/script/02variant/vcf_to_indellist_v1.5.pl -i $outdir/variation_dir/variants_anno_dir/samples.pop.indel.anno.result.vcf "
			. " -o $outdir/variation_dir/variants_anno_dir/samples.pop.indel.anno.result.list -ref 1 ";
	print CMD $cmd4,"\n",$cmd5,"\n",$cmd6,"\n";
}
close (CMD) ;
Pipline_sh_commands("Variant_Annotation.cmds","Variant_Annotation.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 6.3 : gatk MergeVcfs --------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
open (CMD,">","$cmds_dir/gatk_MergeVcfs.cmds") or die $!;
mkdir "$outdir/variation_dir/MergeVcfs" unless (-d "$outdir/variation_dir/MergeVcfs") ;
{
	my $cmd1 = " $gatk MergeVcfs -I $outdir/variation_dir/variants_anno_dir/samples.pop.snp.anno.result.vcf "
			. " -I $outdir/variation_dir/variants_anno_dir/samples.pop.indel.anno.result.vcf "
			. " -O $outdir/variation_dir/MergeVcfs/samples.pop.var.anno.result.vcf.gz "
			. " --TMP_DIR $outdir/variation_dir/MergeVcfs/tmp ";
	print CMD $cmd1,"\n";
}
close (CMD) ;
Pipline_sh_commands("gatk_MergeVcfs.cmds","gatk_MergeVcfs.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 6.4 : gatk Result Stat ------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
mkdir "$outdir/variation_dir/variants_stat" unless (-d "$outdir/variation_dir/variants_stat") ;
open (CMD,">","$cmds_dir/gatk_Stat.cmds") or die $!;
{
	my $cmd1 = " $bcftools stats --threads 10 -s - $outdir/variation_dir/MergeVcfs/samples.pop.var.anno.result.vcf.gz "
				. " > $outdir/variation_dir/variants_stat/samples.var.stat "
				. " && perl $Bin/script/02variant/snp_ver.stat.pl -i $outdir/variation_dir/variants_stat/samples.var.stat "
				. " -o $outdir/variation_dir/variants_stat/snp_var.stat.xls "
				. " && plot-vcfstats -s -p $outdir/variation_dir/variants_stat/samples.var "
				. " $outdir/variation_dir/variants_stat/samples.var.stat -t \"Variations Statistic\" ";

	my $cmd2 = " $python3 $Bin/script/02variant/titv_stat.py -i $outdir/variation_dir/variants_stat/samples.var.stat "
				. " -o $outdir/variation_dir/variants_stat/samples.substitution.xls "
				. " && Rscript $Bin/script/02variant/titv_plot.r --i $outdir/variation_dir/variants_stat/samples.substitution.xls "
				. " --o $outdir/variation_dir/variants_stat/samples.substitution ";

	my $cmd3 = " $perl $Bin/script/02variant/snpeff_snp_anno.stat.pl -id $outdir/variation_dir/variants_anno_dir "
				. " -o $outdir/variation_dir/variants_stat/snp_annotation.stat.xls "
				. " && perl $Bin/script/02variant/snpeff_indel_anno.stat.pl -id $outdir/variation_dir/variants_anno_dir "
				. " -o $outdir/variation_dir/variants_stat/indel_annotation.stat.xls ";

	my $cmd4 = " $perl $Bin/script/02variant/variant_qual.pl -i $outdir/variation_dir/variants_anno_dir/samples.pop.snp.anno.result.vcf "
				. " -o $outdir/variation_dir/variants_stat/snp_cumulative_depth.txt "
				. " && Rscript $Bin/script/02variant/snp_qual.R --dep $outdir/variation_dir/variants_stat/snp_cumulative_depth.txt "
				. " --o $outdir/variation_dir/variants_stat/snp_cumulative_depth ";

	print CMD $cmd1,"\n",$cmd2,"\n";
	print CMD $cmd3,"\n";
	print CMD $cmd4,"\n";
}
close (CMD) ;
Pipline_sh_commands("gatk_Stat.cmds","gatk_Stat_analysis.ok");



print STDERR "\n\n\n----------------------------------------------------------------------------\n"
                  ."--------------------- Step 06 : Vcftools Filter ----------------------------\n"
                  ."----------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/vcf_filter") ;
my $vcf_file="$outdir/variation_dir/variants_anno_dir/samples.pop.snp.anno.result.vcf";

my @chrs;
open (CHR,"<","$main->{Project}{Genome}{chr}") or die $!;
while (<CHR>) {
	chomp;
	next if (/^#/ || /^$/) ;
	my ($chr)=split /\s+/,$_;
	push @chrs,$chr;
}
close (CHR) ;


{
	open (CMD1,">","$cmds_dir/vcf_filter.cmds") or die $!;
	my $cmd1 = " vcftools --min-meanDP 5 --minQ 30 --max-missing 0.70 --maf 0.05 --min-alleles 2 --max-alleles 2 "		# --min-meanDP 5 --minQ 30 --max-missing 0.70 --maf 0.05
				. "--vcf $vcf_file --recode --out $outdir/vcf_filter/samples.pop.snp ";
	print CMD1 $cmd1,"\n";
	close (CMD1) ;
	Pipline_sh_commands("vcf_filter.cmds","vcf_filter.ok",);
}


#过滤后的SNP密度分析
{
	open (CMD,">","$cmds_dir/popSNP_Stat.cmds") or die $!;
#	my $cmd1 = " perl $Bin/script/05vcf_stat/plot_var_density/popSNP_DensityStat.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf "
#				. " -f $outdir/genome/$genome_name.fai -d 20000 -o $outdir/vcf_filter/samples.SNPDensity.stat "
#				. " && Rscript $Bin/script/05vcf_stat/plot_var_density/popSNP_DensityPlot.r $outdir/vcf_filter/samples.SNPDensity.stat "
#				. " 'SNP Density' $outdir/genome/$genome_name.fai ";

	my $cmd1 = " $perl $Bin/script/03vcf/cmplot/cmMarker_filter.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf "
				. " -chrlist $chrlist -o $outdir/vcf_filter/samples.popSNPdensity.list "
				. " && $Rscript $Bin/script/03vcf/cmplot/cmplot.r --binsize 100000 --input $outdir/vcf_filter/samples.popSNPdensity.list "
				. " && mv SNP-Density.Col1_Fig1.Col0_Fig1.pdf $outdir/vcf_filter/samples.popSNPdensity.pdf "
				. " && mv SNP-Density.Col1_Fig1.Col0_Fig1.jpg $outdir/vcf_filter/samples.popSNPdensity.jpg "
				. " && convert -density 600 $outdir/vcf_filter/samples.popSNPdensity.pdf $outdir/vcf_filter/samples.popSNPdensity.png";
			
				#2021/9/13 xul 增加了-chr参数，多生成一个_for_plot 文件，用于绘图展示
	my $cmd2 = " perl $Bin/script/05vcf_stat/plot_var_density/chromSNPStat.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf "
				. " -o $outdir/vcf_filter/samples.SNPStat.xls -chr $chrlist"	
				. " && $Rscript $Bin/script/05vcf_stat/plot_var_density/popSNPNumStat.r $outdir/vcf_filter/samples.SNPStat.xls_for_plot "
				. " $outdir/vcf_filter/samples.SNPStat.pdf "
				. " && convert -density 600 $outdir/vcf_filter/samples.SNPStat.pdf $outdir/vcf_filter/samples.SNPStat.png ";
	print CMD $cmd1,"\n",$cmd2,"\n";
	close (CMD) ;
	Pipline_sh_commands("popSNP_Stat.cmds","popSNP_Stat.ok",);
}



print STDERR "\n\n\n---------------------------------------------------------------------------\n"
                  ."--------------------- Step 07 : PTS ---------------------------------------\n"
                  ."---------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/PTS_analysis") ;
Mkdir("$outdir/PTS_analysis/pca_dir") ;
Mkdir("$outdir/PTS_analysis/admixture_dir") ;
Mkdir("$outdir/PTS_analysis/tree_dir") ;

open (CMD,">","$cmds_dir/vcffiles2plink.cmds") or die $!;

#2022/6/8 xul 无染色体级别的基因组不进行连锁值过滤
if($have_chr){
	print CMD " vcftools --vcf $outdir/vcf_filter/samples.pop.snp.recode.vcf --plink --out $outdir/PTS_analysis/pca_dir/samples.plink \n";
#	print CMD " mv $outdir/PTS_analysis/pca_dir/samples.plink.map $outdir/PTS_analysis/pca_dir/samples.plink.map.bak \n";
#	print CMD " sed -e \'s/^0/1/g\' $outdir/PTS_analysis/pca_dir/samples.plink.map.bak >$outdir/PTS_analysis/pca_dir/samples.plink.map \n";	#无染色体的时候可能会用到这种
	print CMD " plink --file $outdir/PTS_analysis/pca_dir/samples.plink --make-bed --noweb --out $outdir/PTS_analysis/pca_dir/samples.plink.mkbed \n";  ## 文件转换
	print CMD " plink --noweb --file $outdir/PTS_analysis/pca_dir/samples.plink --indep-pairwise 50 5 0.5 --out $outdir/PTS_analysis/pca_dir/samples.plink \n"; ## 20220916 第一次跑流程,这出了问题
	print CMD " plink --noweb --file $outdir/PTS_analysis/pca_dir/samples.plink --extract $outdir/PTS_analysis/pca_dir/samples.plink.prune.in --recode12 --out $outdir/PTS_analysis/pca_dir/samples.plink.recode \n";
}else{
	print CMD " vcftools --vcf $outdir/vcf_filter/samples.pop.snp.recode.vcf --plink --out $outdir/PTS_analysis/pca_dir/samples.plink \n";
	print CMD " perl -i  -lane '++\$i;print \"1\\t\$F[1]\\t0\\t\$i\"'  $outdir/PTS_analysis/pca_dir/samples.plink.map \n";

	print CMD " $plink --noweb --file $outdir/PTS_analysis/pca_dir/samples.plink "
				. " --recode12 --out $outdir/PTS_analysis/pca_dir/samples.plink.recode \n";

	print CMD " $plink --file $outdir/PTS_analysis/pca_dir/samples.plink --make-bed --noweb --out $outdir/PTS_analysis/pca_dir/samples.plink.mkbed \n";
}

close (CMD) ;
Pipline_sh_commands("vcffiles2plink.cmds","plink2mkbed.ok");



open (CMD,">","$cmds_dir/gcta_pca.cmds") or die $!;
{
	my $pca_num= $groupnum > 3 ? $groupnum : 3 ;
	my $cmd1 = " $gcta --bfile $outdir/PTS_analysis/pca_dir/samples.plink.mkbed --make-grm --autosome "
				. " --out $outdir/PTS_analysis/pca_dir/samples --thread-num 10 "#--autosome-num 33
				. " && gcta64 --grm $outdir/PTS_analysis/pca_dir/samples --pca $pca_num "
				. " --out $outdir/PTS_analysis/pca_dir/samples.gcta ";
	my $cmd2 = " $Rscript $Bin/script/10pts/pca/drawPCA_gtca.R -i $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec "
				. " -p $outdir/config_dir/population.list -o $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec "
				. " && $perl $Bin/script/10pts/pca/pca_eigenval2proportion.pl -i $outdir/PTS_analysis/pca_dir/samples.gcta.eigenval "
				. " -o $outdir/PTS_analysis/pca_dir/samples.gcta.eigenval.xls "
				. " && $perl $Bin/script/10pts/pca/pcaEigenQformat.pl -i $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec "
				. " -o $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.xls -p 3 ";
	print CMD $cmd1,"\n",$cmd2,"\n";
	print CMD "convert -density 300 $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.1.pdf $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.1.png\n";
	print CMD "convert -density 300 $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.2.pdf $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.2.png\n";
	print CMD "convert -density 300 $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.3.pdf $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.3.png\n";
	print CMD "convert -density 300 $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.4.pdf $outdir/PTS_analysis/pca_dir/samples.gcta.eigenvec.4.png\n";
}
close (CMD) ;
Pipline_sh_commands("gcta_pca.cmds","gcta_pca.ok");



print STDERR "\n\n\n---------------------------------------------------------------------------\n"
                  ."--------------------- Step 8 : Admixture Structure ------------------------\n"
                  ."---------------------------------------------------------------------------\n\n\n";

Mkdir("$outdir/PTS_analysis/admixture_dir") ;
` cp $outdir/PTS_analysis/pca_dir/samples.plink.recode.ped $outdir/PTS_analysis/admixture_dir/samples.admixture.ped ` unless (-e "$outdir/PTS_analysis/admixture_dir/samples.admixture.ped") ;

open (CMD,">","$cmds_dir/admixture.cmds") or die $!;
for (my $i=2;$i<=16;$i++) {
	print CMD "cd $outdir/PTS_analysis/admixture_dir && admixture --cv $outdir/PTS_analysis/admixture_dir/samples.admixture.ped "
			. " $i | tee $outdir/PTS_analysis/admixture_dir/samples.admixture.$i.log \n";
}
close (CMD) ;
Pipline_parafly_commands("admixture.cmds","admixture_analysis.ok","admixture.failed.cmds",10);


open (CMD,">","$cmds_dir/admixture_plot.cmds") or die $!;
{
	print CMD " perl $Bin/script/10pts/structure/runAdmixturePlot.pl -i $outdir/PTS_analysis/admixture_dir "
				. " -o $outdir/PTS_analysis/admixture_dir \n"; 
	print CMD " perl $Bin/script/10pts/structure/Population_structure.2.0.pl -id $outdir/PTS_analysis/admixture_dir "
				. " -o $outdir/PTS_analysis/admixture_dir/samples.admixture.plot.svg \n";
	print CMD " cat $outdir/PTS_analysis/admixture_dir/samples.admixture.*.log | grep 'CV\\serror\\s\\(K=\\d+\\):' -P > "
				. " $outdir/PTS_analysis/admixture_dir/samples.pop.CV-error.txt \n";
	print CMD " grep '^Loglikelihood' -P $outdir/PTS_analysis/admixture_dir/samples.admixture.*.log "
				. " |perl -ne '\/\(\\d+)\\.log\\:\(Loglikelihood.*\)\/;print \"K=\",\$1,\"\\t\",\$2,\"\\n\"' "
				. " > $outdir/PTS_analysis/admixture_dir/samples.pop.Loglikelihood.txt \n";
	print CMD " python $Bin/script/10pts/structure/k-cv_plot.py "
				. " -i $outdir/PTS_analysis/admixture_dir/samples.pop.CV-error.txt "
				. " -o samples.pop.CV-error.dis.plot -d $outdir/PTS_analysis/admixture_dir \n";
	print CMD " perl $Bin/script/10pts/structure/cnvfmt_pdf2png.pl -i $outdir/PTS_analysis/admixture_dir";
}
close (CMD) ;
Pipline_sh_commands("admixture_plot.cmds","admixture_plot.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 9 : Phylogenetic tree -------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";

Mkdir("$outdir/PTS_analysis/tree_dir") ;
open (CMD,">","$cmds_dir/phytree.cmds") or die $!;
{
	print CMD " perl $Bin/script/10pts/tree/vcf2tree.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf -o $outdir/PTS_analysis/tree_dir/samples \n";
	print CMD " FastTreeMP  -nt -gtr < $outdir/PTS_analysis/tree_dir/samples.fa > $outdir/PTS_analysis/tree_dir/samples.phytree.ML.nwk \n";

	##更换画图程序
#	print CMD " Rscript $Bin/script/10pts/tree/nwk.plot.r --infile $outdir/PTS_analysis/tree_dir/samples.phytree.ML.nwk "
#				. " --outfile $outdir/PTS_analysis/tree_dir/samples.phytree.ML.plot \n";

	print CMD " perl $Bin/script/10pts/tree/draw_tree.pl -i $outdir/PTS_analysis/tree_dir/samples.phytree.ML.nwk -o $outdir/PTS_analysis/tree_dir/ ";
}
close (CMD) ;
Pipline_sh_commands("phytree.cmds","phytree.ok");

my $t6 = threads -> new(\&PSMC);
my $t7 = threads -> new(\&Treemix);

$t6 -> join();
$t7 -> join();

sub PSMC {#
	print STDERR "\n\n\n--------------------------------------------------------------------------------------\n"
					  ."--------- Step 07 : PSMC (Pairwise Sequentially Markovian Coalescent) ---------------\n"
					  ."--------------------------------------------------------------------------------------\n\n\n";
	Mkdir("$outdir/psmc_analysis") ;
	open (CMD,">","$cmds_dir/psmc_analysis.cmds") or die $!;
	{
		my $cmd1 = " perl $Bin/script/06psmc/vcf2psmcGroup.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf -o $outdir/psmc_analysis -g $outdir/config_dir/group.list "
					. " && perl $Bin/script/06psmc/cnvfmt_pdf2png.pl -i $outdir/psmc_analysis ";
		print CMD $cmd1,"\n";
	}
	close (CMD) ;
	Pipline_sh_commands("psmc_analysis.cmds","psmc_analysis.ok");
}


sub Treemix {#
	print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
					  ."--------------------- Step 07 : Treemix ----------------------------------------\n"
					  ."--------------------------------------------------------------------------------\n\n\n";
	

	open (CMD1,">","$cmds_dir/treemix_analysis.cmds") or die $!;
	open (CMD2,">","$cmds_dir/treemix_plot.cmds") or die $!;
	my $has_enough = 1;
	{
		my $cmd1 = " python $Bin/script/07treemix/vcf2treemix.py $outdir/vcf_filter/samples.pop.snp.recode.vcf "
					. " $outdir/config_dir/group.list $outdir/treemix/samples.pop.info.gz ";
		print CMD1 $cmd1,"\n";

		if (scalar@groups <= 4 and @groups >= 3) {
			for (my $i=0;$i<2 ;$i++) {
				my $cmd2 = " treemix -i $outdir/treemix/samples.pop.info.gz -o $outdir/treemix/samples.pop.treemix.$i -bootstrap -k 1000 -m $i "
						. " && Rscript $Bin/script/07treemix/treemix_plot.r --group $outdir/config_dir/group.txt "
						. " --tree $outdir/treemix/samples.pop.treemix.$i --resid $outdir/treemix/samples.pop.treemix.$i ";
				print CMD2 $cmd2,"\n";
			}
		}elsif(@groups > 4){
			for (my $i=0;$i<@groups ;$i++) {
				my $cmd2 = " treemix -i $outdir/treemix/samples.pop.info.gz -o $outdir/treemix/samples.pop.treemix.$i -bootstrap -k 1000 -m $i "
						. " && Rscript $Bin/script/07treemix/treemix_plot.r --group $outdir/config_dir/group.txt "
						. " --tree $outdir/treemix/samples.pop.treemix.$i --resid $outdir/treemix/samples.pop.treemix.$i ";
				print CMD2 $cmd2,"\n";
			}
		}else{
			$has_enough = 0;
		}
	}
	my $cmd3 = " perl $Bin/script/10pts/structure/cnvfmt_pdf2png.pl -i $outdir/treemix ";
	print CMD2 $cmd3,"\n";
	
	close (CMD1) ;
	close (CMD2) ;

	if($has_enough){
		Mkdir("$outdir/treemix") ;
		Pipline_sh_commands("treemix_analysis.cmds","treemix_analysis.ok") ;
		Pipline_sh_commands("treemix_plot.cmds","treemix_plot.ok");
	}
	
}



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 12 : LDdecay ----------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/LDdecay_dir") ;

open (CMD1,">","$cmds_dir/LDdecay_analysis.cmds") or die $!;
open (CMD2,">","$cmds_dir/LDdecay_plot.cmds") or die $!;
open (DATA,">","$outdir/LDdecay_dir/mutidecay.file") or die $!;

foreach my $group (@groups) {
	my $cmd1 = " $PopLDdecay/PopLDdecay -InVCF $outdir/vcf_filter/samples.pop.snp.recode.vcf -OutStat $outdir/LDdecay_dir/$group -OutPairLD 5 "
				. " -MAF 0.05 -MaxDist 300 -Miss 0.7 -SubPop $outdir/config_dir/$group.list ";

	my $cmd2 = " perl $PopLDdecay/Plot_OnePop.pl -inFile $outdir/LDdecay_dir/$group.stat.gz "
				. " -output $outdir/LDdecay_dir/$group.LDdecay.plot -keepR ";

	print CMD1 $cmd1," && ",$cmd2,"\n";
	print DATA "$outdir/LDdecay_dir/$group.stat.gz\t$group\n";
}
print CMD2 "perl $PopLDdecay/Plot_MultiPop.pl -inList $outdir/LDdecay_dir/mutidecay.file "
			. " -output $outdir/LDdecay_dir/mutigroups.LDdecay.plot -keepR \n"; 

close (CMD1) ;
close (CMD2) ;
Pipline_parafly_commands("LDdecay_analysis.cmds","LDdecay_analysis.ok","LDdecay_analysis.failed.cmds",10);
Pipline_sh_commands("LDdecay_plot.cmds","LDdecay_plot.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 13: PopGen statistic --------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
mkdir "$outdir/popGenStat_dir" unless (-d " $outdir/popGenStat_dir") ;
{
	open (CMD,">","$cmds_dir/popGenStat.cmds") or die $!;
	print CMD " perl $Bin/script/11PopGen/vcf2popstat.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf "
				. " -p $outdir/config_dir/population.list -o $outdir/popGenStat_dir \n";
	print CMD " perl $Bin/script/11PopGen/FstPopStats.pl -i $outdir/popGenStat_dir -o $outdir/popGenStat_dir/FstNm.stat.xls \n";
	#print CMD " perl $Bin/script/11PopGen/GeneticDistanceCal.pl -i $outdir/popGenStat_dir/samples.snp.tab -o $outdir/popGenStat_dir/genetic_dis \n";
	#print CMD " perl $Bin/script/11PopGen/GeneticDistanceCalMerge.pl -i $outdir/popGenStat_dir/genetic_dis -o $outdir/popGenStat_dir/genetic_dis \n";
	close (CMD) ;
}
Pipline_sh_commands("popGenStat.cmds","popGenStat_analysis.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 14: ROH Analysis ------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	Mkdir("$outdir/ROH_dir") ;
	open (CMD,">","$cmds_dir/roh_analysis.cmds") or die $!;
	my $cmd1 = " $plink --vcf $outdir/vcf_filter/samples.pop.snp.recode.vcf --recode --out $outdir/ROH_dir/samples.plink --allow-extra-chr ";

	my $cmd2 = " $python3 $Bin/script/14ROH/ped2cnvfmt.py -i $outdir/ROH_dir/samples.plink.ped -g $outdir/config_dir/group.list -o $outdir/ROH_dir/samples.fmt.ped ";

	my $cmd3 = " $python3 $Bin/script/14ROH/map2cnvfmt.py -i $outdir/ROH_dir/samples.plink.map -o $outdir/ROH_dir/samples.fmt.map ";

#	my $cmd4 = " $Rscript $Bin/script/14ROH/run_dR_cr_ROHet.R $outdir/ROH_dir/samples.fmt.ped "
#				. " $outdir/ROH_dir/samples.fmt.map 33 $outdir/ROH_dir ";

	my $cmd4 = " $Rscript $Bin/script/14ROH/run_dR_cr_ROHom_v2.R $outdir/ROH_dir/samples.fmt.ped "
				. " $outdir/ROH_dir/samples.fmt.map 33 $outdir/ROH_dir ";
	print CMD $cmd1,"\n",$cmd2,"\n",$cmd3,"\n",$cmd4,"\n";
	close (CMD) ;
	Pipline_sh_commands("roh_analysis.cmds","roh_analysis.ok");
}




print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 6.4 : SnpEff Stat -----------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/vcf_filter/SnpEff_stat") ;
open (CMD,">","$cmds_dir/snpEff_Anno.cmds") or die $!;
my $var="snp";
{
	my $prefix=$main->{Project}{Programs}{SNPEFF}{dbname};
	my $SNPEFF_JAR='/share/nas6/zhouxy/biosoft/snpEff/current/snpEff.jar';
	for (my $i=0;$i<@groups;$i++) {
		my $cmd0 = " $gatk SelectVariants -R $outdir/genome/$genome_name "
			. " -V $outdir/vcf_filter/samples.pop.snp.recode.vcf "
			. " --select-type-to-include SNP --exclude-non-variants "
			. "--sample-name $outdir/config_dir/$groups[$i].list"
			. " -O $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.vcf ";
		print CMD $cmd0," && ";

		my $cmd1 = " $java -jar $SNPEFF_JAR $prefix -o gatk "
				 . " -csvStats $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.snpEff.csv "
				 . " -s $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.snpEff.html "
				 . " -c $outdir/variation_dir/snpeff_index/$prefix.config "
				 . " -v $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.vcf "
				 . " > $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.vcf ";

		my $cmd2 = " $perl $Bin/script/02variant/extract_oneEff_anno.pl -i $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.vcf "
				 . " -o $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf " ;

		if ($var eq "snp") {
			my $cmd3 = " $perl $Bin/script/02variant/vcf_to_snplist_v1.5.pl -i $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf "
					. " -o $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf.list -ref 1 ";

			my $cmd4 = " $perl $Bin/script/02variant/vcf2snplist_stat.pl -i $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf.list "
					. " -o $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf.list.stat";
			print CMD $cmd1," && ",$cmd2," && ",$cmd3," && ",$cmd4,"\n";
		}else{
			my $cmd3 = " $perl $Bin/script/02variant/vcf_to_indellist_v1.5.pl -i $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf "
					. " -o $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf.list -ref 1 ";

			my $cmd4 = " $perl $Bin/script/02variant/vcf2snplist_stat.pl -i $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf.list "
					. " -o $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.$var.anno.result.vcf.list.stat ";

			print CMD $cmd1," && ",$cmd2," && ",$cmd3," && ",$cmd4,"\n";
		}
	}
	my $cmd1 = " $java -jar $SNPEFF_JAR $prefix -o gatk "
			 . " -csvStats $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.snpEff.csv "
			 . " -s $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.snpEff.html "
			 . " -c $outdir/variation_dir/snpeff_index/$prefix.config "
			 . " -v $outdir/vcf_filter/samples.pop.snp.recode.vcf "
			 . " > $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.vcf ";

	my $cmd2 = " perl $Bin/script/02variant/extract_oneEff_anno.pl -i $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.vcf "
			 . " -o $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf " ;

	if ($var eq "snp") {
		my $cmd3 = " $perl $Bin/script/02variant/vcf_to_snplist_v1.5.pl -i $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf "
				. " -o $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf.list -ref 1 ";

		my $cmd4 = " $perl $Bin/script/02variant/vcf2snplist_stat.pl -i $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf.list "
				. " -o $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf.list.stat ";
		print CMD $cmd1," && ",$cmd2," && ",$cmd3," && ",$cmd4,"\n";
	}else{
		my $cmd3 = " $perl $Bin/script/02variant/vcf_to_indellist_v1.5.pl -i $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf "
				. " -o $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf.list -ref 1 ";

		my $cmd4 = " $perl $Bin/script/02variant/vcf2snplist_stat.pl -i $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf.list "
				. " -o $outdir/vcf_filter/SnpEff_stat/samples.pop.$var.anno.result.vcf.list.stat ";

		print CMD $cmd1," && ",$cmd2," && ",$cmd3," && ",$cmd4,"\n";
	}
}
close (CMD) ;
Pipline_parafly_commands("snpEff_Anno.cmds","snpEff_Anno.ok","snpEff_Anno.failed.cmds",20);



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 04 : Variant Merge ----------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
Mkdir("$outdir/variation_dir/variants_stat") ;

open (CMD,">","$cmds_dir/snpEff_merge.cmds") or die $!;
{
	my $cmd1 = " perl $Bin/script/02variant/vcf2snplist_stat_merge.pl -i $outdir/vcf_filter/SnpEff_stat "
			. " -o $outdir/vcf_filter/SnpEff_stat/samples.snpEff.anno.xls ";
	
	my $cmd2 = " $perl $Bin/script/04snpeff/snpeff_$var\_anno_stat_filter.pl -i $outdir/vcf_filter/SnpEff_stat/samples.snpEff.anno.xls "
			. " -o $outdir/vcf_filter/SnpEff_stat/samples.snpEff.stat.xls "
			. " && $Rscript $Bin/script/04snpeff/for_snpEff_his_plot.r $outdir/vcf_filter/SnpEff_stat/samples.snpEff.stat.xls "
			. " $outdir/vcf_filter/SnpEff_stat/samples.snpEff.stat.pdf "
			. " && convert -density 600 $outdir/vcf_filter/SnpEff_stat/samples.snpEff.stat.pdf "
			. " $outdir/vcf_filter/SnpEff_stat/samples.snpEff.stat.png ";
	print CMD $cmd1,"\n",$cmd2,"\n";
}
close (CMD) ;
Pipline_sh_commands("snpEff_merge.cmds","snpEff_merge.ok");


print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 05 : Het Hom ----------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	Mkdir("$outdir/vcf_filter/SnpEff_stat") ;
	open (CMD,">","$cmds_dir/variant_hethom.cmds") or die $!;
	my $cmd1 = " $perl $Bin/script/02variant/het_hom_snp2site_stat_v2.pl -i $outdir/vcf_filter/SnpEff_stat "
				. " -o $outdir/vcf_filter/SnpEff_stat/samples.het_hom.stat.xls "
				. " && $Rscript $Bin/script/02variant/het_hom_snp2site_stat.r $outdir/vcf_filter/SnpEff_stat/samples.het_hom.stat.xls "
				. " $outdir/vcf_filter/SnpEff_stat/samples.het_hom.stat.pdf "
				. " && convert -density 600 $outdir/vcf_filter/SnpEff_stat/samples.het_hom.stat.pdf "
				. " $outdir/vcf_filter/SnpEff_stat/samples.het_hom.stat.png ";
	print CMD $cmd1,"\n";
	close (CMD) ;
}
Pipline_sh_commands("variant_hethom.cmds","variant_hethom.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 06 : Variant TSTV -----------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	Mkdir("$outdir/variation_dir/variants_tstv") ;
	open (CMD,">","$cmds_dir/variant_tstv.cmds") or die $!;
	for (my $i=0;$i<@groups ;$i++) {
		my $cmd1 = " cat $outdir/vcf_filter/SnpEff_stat/$groups[$i].pop.snp.vcf | vcf-tstv "
				. " > $outdir/variation_dir/variants_tstv/$groups[$i].pop.tstv ";
		print CMD $cmd1,"\n";
	}
	my $cmd1 = " cat $outdir/vcf_filter/samples.pop.snp.recode.vcf | vcf-tstv "
			. " > $outdir/variation_dir/variants_tstv/samples.pop.tstv ";
	print CMD $cmd1,"\n";

	my $cmd2 = " perl $Bin/script/02variant/variants_tstv_stat.pl -i $outdir/variation_dir/variants_tstv "
			. " -o $outdir/variation_dir/variants_tstv/samples.pop.tstv.xls ";
	print CMD $cmd2,"\n";
	close (CMD) ;
}
Pipline_sh_commands("variant_tstv.cmds","variant_tstv.ok");



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 06 : Sweep -----------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	Mkdir("$outdir/ssweep_dir") ;
	open (CMD,">","$cmds_dir/ssweep.cmds") or die $!;
	my $cmd1 = " $perl $Bin/script/08ssweep/ssweep_pip_v3.pl -i $infile -v $outdir/vcf_filter/samples.pop.snp.recode.vcf "
				. " -g $outdir/config_dir/group.list -o $outdir/ssweep_dir ";
	print CMD $cmd1,"\n";
	close (CMD) ;
	
	#2021/9/23 xul 增加分组判断
	if(exists $main->{'Project'}{'Contrast'}){
		print "NO contrast\n";
	}else{
		Pipline_sh_commands("ssweep.cmds","ssweep.ok") unless($main->{Project}{Groups}{All});
	}
}




print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 06 : SSR Density ------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	#perl /share/nas6/zhouxy/pipline/genetic_diversity_pip/current/script/16SSR/ssr_diff_v2.pl -i ../analysis/vcf_filter/samples.pop.indel.recode.vcf -fa ../analysis/genome/Csali_genome_v1.fa -g group.list -o results1
	Mkdir("$outdir/ssr_densign") ;
	open (CMD,">","$cmds_dir/ssr_densign.cmds") or die $!;
	my $cmd1 = " $perl $Bin/script/16SSR/ssr_diff_v2.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf "
				. " -fa $outdir/genome/$genome_name -g $outdir/config_dir/group.list -o $outdir/ssr_densign ";
	
	my $cmd2 = " $perl $Bin/script/16SSR/script/regionSeq_substr_v2.pl -i $outdir/ssr_densign/samples.ssr_site.xls "
				. " -g $outdir/genome/$genome_name -l 300 -o $outdir/ssr_densign/samples.ssr_site.primer-design.fasta ";

	my $cmd3 = " $perl $Bin/script/16SSR/script/primer3_in.pl -i $outdir/ssr_densign/samples.ssr_site.primer-design.fasta "
				. " -o $outdir/ssr_densign/primer-design.p3in ";

	my $cmd4 = " $primer3_core < $outdir/ssr_densign/primer-design.p3in > $outdir/ssr_densign/primer-design.p3out "
				. " && perl $Bin/script/16SSR/script/primer3_out.pl -i $outdir/ssr_densign/primer-design.p3out "
				. " -o $outdir/ssr_densign/primer-design.result.xls "
				. " && perl $Bin/script/16SSR/script/cnvfmt_merge.pl -s $outdir/ssr_densign/samples.ssr_site.xls "
				. " -i $outdir/ssr_densign/primer-design.result.xls "
				. " -o $outdir/ssr_densign/primer-design.result.info.xls ";
	print CMD $cmd1,"\n",$cmd2,"\n",$cmd3,"\n",$cmd4,"\n";
	close (CMD) ;
#	Pipline_sh_commands("ssr_densign.cmds","ssr_densign.ok");
}




print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 06 : Population Marker ------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	open (CMD,">","$cmds_dir/markerfilter.cmds") or die $!;
	my $cmd0 = "$perl $Bin/script/11PopGen/vcf2SNPtab.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf -o $outdir/vcf_filter/samples.pop.snp.recode.vcf.tab -ref 0" ;
	my $cmd1 = " $perl $Bin/script/11PopGen/SNP2tabAEStatFilter.pl -i $outdir/vcf_filter/samples.pop.snp.recode.vcf.tab "
#				. " -g $outdir/config_dir/group.list -o $outdir/Markerfilter ";
				. " -g $outdir/config_dir/group.list -o $outdir/popMarker ";
	print CMD $cmd0,"\n",$cmd1,"\n";
	close (CMD) ;
	Pipline_sh_commands("markerfilter.cmds","markerfilter.ok") unless($main->{Project}{Groups}{All});
}



print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step 14: GWAS TASSEL -------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
{
	open (CMD,">","$cmds_dir/GWAS.cmds") or die $!;
	my $cmd1 = " $perl /share/nas6/zhouxy/pipline/gwas_vcf_pip/current/gwas_ped_pip_v2.pl -i $infile "
				. " -v $outdir/vcf_filter/samples.pop.snp.recode.vcf -o $outdir/GWAS ";
	print CMD $cmd1,"\n";
	close (CMD) ;
	Pipline_sh_commands("GWAS.cmds","GWAS.ok") if(defined $main->{Project}{Genome}{phe});
}


print STDERR "\n\n\n--------------------------------------------------------------------------------\n"
                  ."--------------------- Step xxx : MSMC ------------------------------------------\n"
                  ."--------------------------------------------------------------------------------\n\n\n";
mkdir "$outdir/msmc_analysis" unless (-d "$outdir/mcmc_analysis") ;
{
	my $cmd1 = " /share/nas6/zhouxy/biosoft/paml/current/bin/mcmctree  ";
}


##----------------------------------------------------------------------------------------------
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
##----------------------------------------------------------------------------------------------
sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub readConfig{
	my $configFile=shift;
	my $d=Config::General->new(-ConfigFile => "$configFile");
	my %config=$d->getall;
	return %config;
}

sub Mkdir {#
	my ($dir)=@_;
	mkdir $dir unless (-d $dir) ;
}

sub Pipline_cmd_commands {
	my ($commands,$flag)=@_;
	my $pipeliner = new Pipeliner(-verbose => $VERBOSE);
	$pipeliner->add_commands( new Command($commands, "$flag_dir/$flag"));
	$pipeliner->run();
}

sub Pipline_sh_commands {#
	my ($commands,$flag)=@_;
	my $pipeliner = new Pipeliner(-verbose => $VERBOSE);
	$cmd = " sh $cmds_dir/$commands ";
	$pipeliner->add_commands( new Command($cmd, "$flag_dir/$flag"));
	$pipeliner->run();
}

sub Pipline_qsub_commands {#
	my ($commands,$flag,$cpu)=@_;
	my $pipeliner = new Pipeliner(-verbose => $VERBOSE);

	$cmd = " ssh cluster qsub-sge.pl --maxproc $cpu --queue general.q --resource vf=2.5G --reqsub $cmds_dir/$commands --Check --independent ";
	$pipeliner->add_commands( new Command($cmd, "$flag_dir/$flag"));
	$pipeliner->run();
}


sub Pipline_parafly_commands {#
	my ($commands,$flag,$fail_commands,$cpu)=@_;
	my $pipeliner = new Pipeliner(-verbose => $VERBOSE);

	$cmd = " ParaFly -c $cmds_dir/$commands -CPU $cpu -shuffle -failed_cmds $cmds_dir/$fail_commands ";
	$pipeliner->add_commands( new Command($cmd, "$flag_dir/$flag"));
	$pipeliner->run();
}


sub USAGE {#
	my $usage=<<"USAGE";

Script  : $Script
Version : $version
Author  : zhouxy <zhouxy\@genepioneer.com> 
Function:
		Population Pipline Analysis


Usage:
	Options:
	-i	<infile>	input YAML config
	-c		have chr ? 1 : 0;
	-o	<outdir>	outdir


USAGE
	print $usage;
	exit;
}
