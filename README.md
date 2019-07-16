# crispedit
**Nextflow pipeline for inference of CRISPR edits from NGS (Amplicon Sequencing) data**

```
nextflow run crispedit/crisedit.nf --in_fastq LC25_18_3433_BADC3_4_6_313418w_BG6.fastq --ref canola_badc_allgenes.fa --out_dir ${PWD}/myProject --project_name LC25
```

```
N E X T F L O W  ~  version 19.04.1
Launching `crispedit/crisedit.nf` [big_blackwell] - revision: 41417d8f3c
[warm up] executor > local
executor >  local (83)
[6d/918cb1] process > fastqToFasta          [100%] 1 of 1 ✔
[90/e49df1] process > dereplication         [100%] 1 of 1 ✔
[76/daf026] process > clustering            [100%] 1 of 1 ✔
[7e/b54e6c] process > mapHighFrequencyReads [100%] 1 of 1 ✔
[a3/053e40] process > samToBam              [100%] 1 of 1 ✔
[14/74b006] process > identiyEdits          [100%] 1 of 1 ✔
[9a/c129d3] process > indexBam              [100%] 1 of 1 ✔
[a0/cbdf9a] process > prepForPSA            [100%] 1 of 1 ✔
[48/4c5ef7] process > performPSA            [100%] 37 of 37 ✔
[65/be3e70] process > combineClustalOut     [100%] 37 of 37 ✔
[03/da9217] process > createFinalReport     [100%] 1 of 1 ✔

Completed at: 16-Jul-2019 12:05:50
Duration    : 22.3s
CPU hours   : (a few seconds)
Succeeded   : 83
```

### Credits
crispedit was originally written by Netsanet Gebremedhin.
