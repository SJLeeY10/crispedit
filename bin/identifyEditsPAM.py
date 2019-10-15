#!/usr/bin/env python

import sys
from Bio.Seq import Seq

sgRna = sys.argv[2]

# sgRnas = ["GATTTGTTCATGGGCTCAGAAGG",
# "GCTCGTTCCCAAGCCCTCTGAGG",
# "GCTTGTTCCCAAGCCCTCTGAGG",
# "CCTTCTGAGCCCATGAACAAATC",
# "GATTTGTTCATGGGCTCAGAAGG"
# "CCTCAGAGGGCTTGGGAACGAGC"]


randomSeq= []
ampliconReads = []


with open(sys.argv[1]) as mapFile:
	for line in mapFile:
		cols = line.strip().split("\t")
		sequence_count = cols[0].split(";")[1].split("=")[1]
		if sgRna in cols[2]:
			indexSgRna = cols[2].find(sgRna)
			ampliconReads.append(cols[0])
			print(str(sequence_count) + "\t" + "Wildtype" + "\t" + cols[1]  + "\t" + "NA" + "\t" + cols[2] + "\t" + cols[3])
		elif sgRna in Seq(cols[2]).reverse_complement(): # Check in the reverse complement as well
			ampliconReads.append(cols[0])
			print(str(sequence_count) + "\t" + "Wildtype" + "\t" + cols[1]  + "\t" + "NA" + "\t" + cols[2] + "\t" + cols[3])
		else:
			for i in range(len(sgRna)-1,0,-1):
					if sgRna[0:i] in cols[2]:
						indexSgRna = cols[2].find(sgRna[0:i])
						# ignore those high frequency reads that contain only a small stretch of the sgRNA
						if len(cols[2][indexSgRna:indexSgRna+len(sgRna)+1]) < 15:
							continue
						# if the portion of guide RNA found in the high frequency sequence is too short, it could be just a random sequence, so ignore
						if len(sgRna[0:i]) < 10:
							# Random  or non-specific amplication, count and report
							randomSeq.append(cols[0])
							continue 
						
						if cols[2][indexSgRna:indexSgRna+len(sgRna)+1].find("GAGG")==20:
							# This must be an insertion
							# print "Insertion" + "\t" + cols[1] + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1] + "\t" + str(len(cols[2][indexSgRna:indexSgRna+len(sgRna)+1])) + "\t" + sgRna[0:i] + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1][len(sgRna[0:i])]
							ampliconReads.append(cols[0])
							print(str(sequence_count) + "\t" + "Insertion" + "\t" + cols[1]  + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1][len(sgRna[0:i])] + "\t" + cols[2] + "\t" + cols[3])
							break
						elif cols[2][indexSgRna:indexSgRna+len(sgRna)+1].find("GAGG")!=20:
							#This must be a deletion
							# print "Deletion" + "\t" + cols[1] + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1] + "\t" + str(len(cols[2][indexSgRna:indexSgRna+len(sgRna)+1])) + "\t" + sgRna[0:i] + "\t" + sgRna[len(sgRna[0:i])]
							ampliconReads.append(cols[0])
							print(str(sequence_count) + "\t" + "Deletion" + "\t" + cols[1] +  "\t" + sgRna[len(sgRna[0:i])] + "\t" + cols[2] + "\t" + cols[3])
							break
					elif sgRna[0:i] in Seq(cols[2]).reverse_complement():
						##
						## TO-DO: This block is duplicated for testing and quick deliver, get it into a function
						##
						indexSgRna = cols[2].find(sgRna[0:i])
						# ignore those high frequency reads that contain only a small stretch of the sgRNA
						if len(cols[2][indexSgRna:indexSgRna+len(sgRna)+1]) < 23:
							continue
						# if the portion of guide RNA found in the high frequency sequence is too short, it could be just a random sequence, so ignore
						if len(sgRna[0:i]) < 10:
							# Random  or non-specific amplication, count and report
							randomSeq.append(cols[0])
							continue 
						
						if cols[2][indexSgRna:indexSgRna+len(sgRna)+1].find("GAGG")==20:
							# This must be an insertion
							# print "Insertion" + "\t" + cols[1] + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1] + "\t" + str(len(cols[2][indexSgRna:indexSgRna+len(sgRna)+1])) + "\t" + sgRna[0:i] + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1][len(sgRna[0:i])]
							ampliconReads.append(cols[0])
							print(str(sequence_count) + "\t" + "Insertion" + "\t" + cols[1]  + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1][len(sgRna[0:i])] + "\t" + cols[2] + "\t" + cols[3])
							break
						elif cols[2][indexSgRna:indexSgRna+len(sgRna)+1].find("GAGG")!=20:
							#This must be a deletion
							# print "Deletion" + "\t" + cols[1] + "\t" + cols[2][indexSgRna:indexSgRna+len(sgRna)+1] + "\t" + str(len(cols[2][indexSgRna:indexSgRna+len(sgRna)+1])) + "\t" + sgRna[0:i] + "\t" + sgRna[len(sgRna[0:i])]
							ampliconReads.append(cols[0])
							print(str(sequence_count) + "\t" + "Deletion" + "\t" + cols[1] +  "\t" + sgRna[len(sgRna[0:i])] + "\t" + cols[2] + "\t" + cols[3])
							break

## Report random sequences or sequences that does not contain guide RNA
count_random_reads = []
for k in set(randomSeq):
	count_random_reads.append(int(k.split(";")[1].split("=")[1]))

print(str(sum(count_random_reads)) + "\tNA\tRandom\tNA\tNA\tNA")


# Report amplicon reads, not yet

count_amplicon_reads = []
for k in set(ampliconReads):
	count_amplicon_reads.append(int(k.split(";")[1].split("=")[1]))
# print str(sum(count_amplicon_reads))
# print str(sum(count_amplicon_reads)) + "\tNA\tAmplicon\tNA\tNA\tNA"

