#!/bin/bash

hfrFile=$1
referenceFile=$2

# Create a file that will be input to clustalO with column names precreated. 
printf "PSA Input\n" > clustalO_input.txt

while read line

do 

frequency=$(echo $line|awk '{ print $1 }')
cigar=$(echo $line|awk '{ print $4 }')
region=$(echo $line|awk '{ print $2 }')
mapStart=$(echo $line|awk '{ print $3 }')
targetSequence=$(echo $line|awk '{ print $5 }')
referenceSequence=$(cat ${referenceFile}|awk   "/${region}/{getline; print }")

#TO-DO: Do not hard-code read length - 142 below
mapStop=`expr ${mapStart} + 141`

referenceSubSequence=$(echo ${referenceSequence}|cut -c${mapStart}-${mapStop})

#echo $referenceSubSequence
printf ">${region}|${frequency}|${mapStart}|${cigar}\n${targetSequence}\n" > ${region}_${frequency}_${mapStart}_target.fa
#TO-DO: - Low Priority - A reference file probably is being created multiple times in 
#different files names while the content remains the same

printf ">${region}\n${referenceSubSequence}\n" >> ${region}_${frequency}_${mapStart}_target.fa

printf "${region}_${frequency}_${mapStart}_target.fa\n" >> clustalO_input.txt

done<$hfrFile
