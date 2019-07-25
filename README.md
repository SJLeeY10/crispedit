# crispedit
**Nextflow pipeline for inference of CRISPR edits from NGS (Amplicon Sequencing) data**

```
run crispedit/crisedit.nf --in_fastq  /Users/ngebremedhin/Downloads/VB26_18_3428_P1087_308811w_BF8.fastq  --ref canola_badc_allgenes.fa --out_dir ${PWD}/myProject --project_name LC25 --bucket bioinformatics-analysis-netsanet --sgrna "CCTTCTGAGCCCATGAACAAATC"
```

```
N E X T F L O W  ~  version 19.04.1
Launching `crispedit/crisedit.nf` [hopeful_swanson] - revision: 607eaca8d5

[warm up] executor > local
executor >  local (27)
[a7/a397c1] process > mergeReads            [100%] 1 of 1 ✔
[58/d46b33] process > clustering            [100%] 1 of 1 ✔
[1d/5e8374] process > dereplication         [100%] 1 of 1 ✔
[bb/cc12b3] process > mapHighFrequencyReads [100%] 1 of 1 ✔
[44/eec241] process > samToBam              [100%] 1 of 1 ✔
[92/c84f30] process > indexBam              [100%] 1 of 1 ✔
[d2/119094] process > identiyEdits          [100%] 1 of 1 ✔
[a2/38c0af] process > prepForPSA            [100%] 1 of 1 ✔
[a6/51cabd] process > performPSA            [100%] 9 of 9 ✔
[bd/fd96a3] process > combineClustalOut     [100%] 9 of 9 ✔
[33/0f5567] process > createFinalReport     [100%] 1 of 1 ✔

Completed at: 25-Jul-2019 11:37:08
Duration    : 12.4s
CPU hours   : (a few seconds)
Succeeded   : 27
```

### Credits
crispedit is written by Netsanet Gebremedhin.
