#!/usr/bin/env nextflow
/*

 CRISP Edits Visualization Pipeline
 https://github.com/gnetsanet/crispedit
*/





/*
 * STEP 1 - Converting fastq to fasta
 */

process fastqToFasta {

  tag "${fastq}.baseName"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  val(fastq) from Channel.fromPath(params.in_fastq)

  output:
  file("${fastq.baseName}.fasta") into (in_fasta_cluster, in_fasta_dereplicate)


  script:
  """
  reformat.sh in=${fastq} out=${fastq.baseName}.fasta
  """
}

/*
 * STEP 2 - Clustering
 */

process clustering {

    tag "Clustering"

    publishDir "${params.out_dir}", mode: 'copy'

    input:
    file fasta1 from in_fasta_cluster
    val(reference) from Channel.fromPath(params.ref)

    output:
    file "${fasta1.baseName}.alnout.txt" into cluster_out



    script:
    """
    vsearch --usearch_global ${fasta1} --db ${reference} --id 0.9 --alnout ${fasta1.baseName}.alnout.txt
    """
}

/*
 * STEP 3 - Dereplication
 */

process dereplication {

    tag "Dereplication"

    publishDir "${params.out_dir}", mode: 'copy'

    input:
    file fasta2 from in_fasta_dereplicate
    val(reference) from Channel.fromPath(params.ref)

    output:
    file "${fasta2.baseName}_unique_seqs.fa" into dereplicate_out
  
    script:
    """
    vsearch --derep_fulllength ${fasta2} -sizeout -output ${fasta2.baseName}_unique_seqs.fa --minuniquesize 100 --strand both
    """
}


/*
 * STEP 4 - Mapping high frequency reads
 */

process mapHighFrequencyReads {

  tag "Mapping"

  publishDir "${params.out_dir}", mode: 'copy'

  
  input:
  file uniq_seqs from dereplicate_out
  val(reference) from Channel.fromPath(params.ref)

  output:
  file "${uniq_seqs.baseName}.sam" into sam
  

  script:
  """
  bwa mem ${reference} ${uniq_seqs} > ${uniq_seqs.baseName}.sam
  """
}


/*
 * STEP 5 - Identifying edits
 */

process identiyEdits {
  tag "Identifying edits"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  file mapfile from sam

  output:
  file "*.edits.hfr.txt" into hfr_file

  script:
  """
  cigar2seq.py ${mapfile} > ${mapfile.baseName}.edits.hfr.txt
  """
}



/*
 * STEP 6 - Performing pair-wise alignment between high-frequence reads
 * and the region they are mapped to
 */

process prepForPSA {

  tag "Pre-processing for PSA"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  //set val(processedHfrFile), file(processedHfr) from hfr_file
  val(processedHfrFile) from hfr_file
  val(reference) from Channel.fromPath(params.ref)


  output:
  file 'clustalO_input.txt' into clustal_inputs

  script:
  """
  createPSAFiles.sh ${processedHfrFile} ${reference} ${params.out_dir} > clustalO_input.txt
  """
}


process performPSA {

  tag "Pair-wise alignment"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  val(clustal_in_fofn) from clustal_inputs.splitCsv(strip:true).map { line -> file(line[0]) }

  output:
  file "${clustal_in_fofn.baseName}.clustal.out" into clustal_outs

  script:
  """
  clustalo  --in=${clustal_in_fofn} > ${clustal_in_fofn.baseName}.clustal.out 
  """
}

