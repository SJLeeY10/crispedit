#!/usr/bin/env python

import re
import sys
from Bio.Seq import Seq

#sgRna = sys.argv[2]



randomSeq= []
ampliconReads = []


with open(sys.argv[1]) as samFile:
	for line in samFile:
		if not line.startswith("@"):
			cols = line.strip().split("\t")
			sequence_count = cols[0].split(";")[1].split("=")[1]
			cigar = cols[5]
			nm_tag = cols[11]
			md_tag = cols[12]

			if nm_tag == "NM:i:0": # Matches the reference: Edit distance of 0, then this must be wild-type
				print(str(sequence_count) + "\t" + "Wildtype" + "\t" + cols[2] +  "\tNA\t" + cols[9] + "\t" + cols[3])
			else:
				deletion = re.search(r'\^',md_tag)
				if deletion != None: # if deletion
					m=re.search(r'(\^([AGCT]+))',md_tag)
					variant = m.group(2)
					print(str(sequence_count) + "\t" + "Deletion" + "\t" + cols[2] +  "\t" + variant + "\t" + cols[9] + "\t" + cols[3])
				else: # if not deletion, go to the cigar string to find the inserted nucleotide/s
					m=re.findall(r'((\d+)(M|I))',cigar)
					z= [m[0:i] for i, x in enumerate(m) if x[2]=='I']

					variant = []
					for i in z:
						variant.append(cols[9][sum(int(x[1]) for x in i)])
					print(str(sequence_count) + "\t" + "Insertion" + "\t" + cols[2] +  "\t" + ' '.join(variant) + "\t" + cols[9] + "\t" + cols[3])

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

