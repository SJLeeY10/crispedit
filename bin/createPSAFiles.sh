#!/bin/bash

hfrFile=$1
referenceFile=$2

# Create a file that will be input to clustalO with column names precreated. 
printf "PSA Input\n" > clustalO_input.txt	
while read line

do 

	region=$(echo $line|awk '{ print $2 }')

	frequency=$(echo $line|awk '{ print $1 }')
	cigar=$(echo $line|awk '{ print $4 }')
	mapStart=$(echo $line|awk '{ print $3 }')
	targetSequence=$(echo $line|awk '{ print $5 }')

	printf ">${region}|${frequency}|${mapStart}|${cigar}\n${targetSequence}\n" > ${region}_${frequency}_targets_ref_psa_input.fa
	
	#TO-DO: Do not hard-code read length - 142 below
	mapStop=`expr ${mapStart} + 141`
	referenceSequence=$(cat ${referenceFile}|awk   "/${region}/{getline; print }")
	referenceSubSequence=$(echo ${referenceSequence}|cut -c${mapStart}-${mapStop})
	printf ">${region}\n${referenceSubSequence}\n" >> ${region}_${frequency}_targets_ref_psa_input.fa
	printf "${region}_${frequency}_targets_ref_psa_input.fa\n" >> clustalO_input.txt
done<$hfrFile