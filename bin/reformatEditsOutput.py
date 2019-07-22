#!/usr/bin/env python

import sys

total_reads = 0
with open(sys.argv[-1]) as editsFile:
	for eachline in editsFile:
		reads = eachline.strip().split("\t")[0]
		total_reads += int(reads)


# print total_reads

with open(sys.argv[-1]) as hfrFile:
	for line in hfrFile:
		entry = line.strip().split("\t")
		read_count = entry[0]
		edit_type = entry[1]
		region = entry[2]
		edit = entry[3]
		sequence = entry[4]
		mapStart = entry[5]

		print ("%s-%s-%s-%s-%s\t%s\t%s\t%s" %(region,edit_type,edit,read_count,round(float(read_count)/total_reads*100,2), region, sequence, mapStart))
	
