#!/bin/bash

hfrFile=$1
referenceFile=$2

# Create a file that will be input to clustalO with column names precreated. 
touch clustalO_input.txt	
while read line

do  
	region=$(printf "%s\n" "$line"|awk -F'\t' '{ print $3 }')
	target_fasta_header=$(printf "%s\n" "$line"|awk -F'\t' '{ print $1 }')
	frequency=$(printf "%s\n" "$line"|awk -F'\t'  '{ print $2 }')
	targetSequence=$(printf "%s\n" "$line"|awk -F'\t'  '{ print $6 }')
	mapStart=$(printf "%s\n" "$line"|awk -F'\t' '{ print $4 }')

	echo $target_fasta_header

	printf ">${target_fasta_header}\n${targetSequence}\n" > ${region}_${frequency}_targets_ref_psa_input.fa
	
	#TO-DO: Do not hard-code read length - 142 below
	mapStop=`expr ${mapStart} + 141`
	referenceSequence=$(cat ${referenceFile}|awk   "/${region}/{getline; print }")
	referenceSubSequence=$(echo ${referenceSequence}|cut -c${mapStart}-${mapStop})
	printf ">${region}\n${referenceSubSequence}\n" >> ${region}_${frequency}_targets_ref_psa_input.fa
	printf "${region}_${frequency}_targets_ref_psa_input.fa\n" >> clustalO_input.txt
done<$hfrFile