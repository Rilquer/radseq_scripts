#!/bin/bash
##Rilquer Mascarenhas
##Version: May 18, 2020 - 21:13
##


while getopts f:n:s: option
do
case "${option}"
in
f) FILE=${OPTARG};;
n) NSAMPLES=${OPTARG};;
s) SNPF=${OPTARG};;

esac
done


if [ "$1" == "--help" ] || [ "$1" == "-h" ] ##Checking whether the help flag was used
then
	echo "Quick script to filter iPyrad alleles file based on number of SNPS
(both informative and singletons).

Basic usage:
	-f 		Path to alleles file
	-n 		Number of samples in your assembly
	-s 		Filter for SNPS (only loci with number of SNPS equal or greater than this
			will be kept
	-h, --help	Show this info"
else
	if [ -z "$FILE" ]
	then
		echo 'You must provide a path to file with flag -f.'
		exit 1
	fi
	if [ -z "$NSAMPLES" ]
	then
		echo 'You must provide number of samples with flag -n.'
		exit 1
	fi
	if [ -z "$SNPF" ]
	then
		echo 'You must provide number of SNPs for filter with flag -s.'
		exit 1
	fi
	echo "Counting SNPs..."
	echo ""
	grep '//' $FILE > count
	pinf=($(awk -F'|' '{print gsub(/*/,"")}' count))
	sing=($(awk -F'|' '{print gsub(/-/,"")}' count))
	loci=($(sed -e 's/\(^.*|\)\(.*\)\(|.*$\)/\2/' count))
	rm count

	declare -a snps=()
	sum=0
	len=${#pinf[@]}
	for ((i=0; i<$len; i++))
	do
		sum=$(( ${pinf[$i]}+${sing[$i]} )) 
		snps=("${snps[@]}" "$sum")
	done
	
	echo "Checking which loci to keep..."
	echo ""
	declare -a kept=()
	for ((i=0; i<$len; i++))
	do
		if [ ${snps[$i]} -ge $SNPF ]
		then
			kept=("${kept[@]}" "${loci[$i]}")
		fi
	done
	ngrep=$(( 2*NSAMPLES + 5 ))
	
	echo "Creating new file:"
	for i in ${kept[@]}
	do
		echo "Writing locus number " ${i}
		grep -B $ngrep "|${i}|" $FILE > draft
		grep -m1 -B $ngrep "|*|" draft > remove
		grep -Fvxf remove draft >> ${FILE}_filtered
		rm draft remove
	done
fi
	
