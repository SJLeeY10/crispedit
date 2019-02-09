#!/bin/bash

hfrFile=$1
referenceFile=$2


while read line

do 

region=$(echo $line|awk '{ print $2 }')
mapStart=$(echo $line|awk '{ print $3 }')
targetSequence=$(echo $line|awk '{ print $5 }')
referenceSequence=$(cat ${referenceFile}|awk   "/${region}/{getline; print }")

#TO-DO: Do not hard-code read length - 142 below
mapStop=`expr ${mapStart} + 142`

referenceSubSequence=$(echo ${referenceSequence}|cut -c${mapStart}-${mapStop})

echo $referenceSubSequence
#echo $region

done<$hfrFile
