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
  file "${uniq_seqs.baseName}.sam" into (sam_copy1, sam_copy2)
  

  script:
  """
  bwa mem ${reference} ${uniq_seqs} > ${uniq_seqs.baseName}.sam
  """
}



/*
 * STEP 5 - Convert SAM to BAM
 */

process samToBam {

  tag "SAM to BAM"

  publishDir "${params.out_dir}", mode: 'copy'

  
  input:
  file inputSam from sam_copy1

  output:
  file "${inputSam.baseName}.bam" into bamFile
  

  script:
  """
  samtools view -S -b ${inputSam} > ${inputSam.baseName}.bam
  """

}



/*
 * STEP 6 - Sort and Index BAM
 */
process indexBam {

  tag "Sort & Index BAM"

  publishDir "${params.out_dir}", mode: 'copy'

  
  input:
  file inputBam from bamFile

  output:
  file("reads.mapped.txt") into mapped_reads_out
  

  script:
  """
  pushd ${params.out_dir}
  samtools sort ${inputBam} -o ${inputBam.baseName}.sorted.bam
  samtools index ${inputBam.baseName}.sorted.bam
  popd
  samtools view -F 4 ${inputBam}|awk -F'\t' '{ print \$1"\t"\$3"\t"\$10"\t"\$4 }'>reads.mapped.txt
  """

}


/*
 * STEP 7 - Identifying edits
 */

process identiyEdits {
  tag "Identifying edits"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  file mapped_reads from mapped_reads_out

  output: 
  file "${mapped_reads.baseName}.edits.txt" into editsFile
  file "${mapped_reads.baseName}.edits.reformatted.txt" into (hfr_file_copy1, hfr_file_copy2)

  script:
  """
  identifyEditsPAM.py ${mapped_reads}|sort -k1,1rn > ${mapped_reads.baseName}.edits.txt
  reformatEditsOutput.py ${mapped_reads.baseName}.edits.txt > ${mapped_reads.baseName}.edits.reformatted.txt
  """
}



/*
 * STEP 8 - Prepare for pairwise alignment between high-frequence reads
 * and the region they are mapped to
 */

process prepForPSA {

  tag "Pre-processing for PSA"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  val(processedHfrFile) from hfr_file_copy1
  val(reference) from Channel.fromPath(params.ref)


  output:
  file 'clustalO_input.txt' into clustal_inputs

  script:
  """
  createPSAFiles.sh ${processedHfrFile} ${reference} ${params.out_dir} > clustalO_input.txt
  """
}


/*
 * STEP 9 - Perform pair-wise alignment 
 */


process performPSA {

  tag "Pair-wise alignment"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  val(clustal_in_fofn) from clustal_inputs.splitCsv(strip:true).map { line -> file(line[0]) }

  output:
  file "${clustal_in_fofn.baseName}.clustal.out" into clustal_out

  script:
  """
  clustalo  --in=${clustal_in_fofn} > ${clustal_in_fofn.baseName}.clustal.out 
  """
}



/*
 * STEP 10 - Combine Clustal Omega outputs
 */
process combineClustalOut {
  tag "Combine clustalO outputs"

  publishDir "${params.out_dir}", mode: 'copy'

  input:
  set val(psa_out_file_comb), val(psa_out_comb) from clustal_out
  .toList().flatten()
  .map {
    file -> tuple(file, file.baseName)
  }

  output:
  file("${psa_out_comb}_combine.complete.txt") into combine_complete_marker

  script:
  """
  cat ${psa_out_file_comb} >> ${params.out_dir}/${params.project_name}.combined.clustal.out
  touch ${psa_out_comb}_combine.complete.txt
  """
}


/*
 * STEP 11 - Create final report
 */
process createFinalReport {
  
  input:
  file '*.complete.txt' from combine_complete_marker.collect()
  file(processedHfrFile) from hfr_file_copy2


  script:
  """
  createReportPackage.sh ${processedHfrFile} ${params.project_name} ${params.out_dir} ${params.project_name}.combined.clustal.out
  cd ${params.out_dir}
  aws s3 cp ${params.project_name}.combined.clustal.out s3://bioinformatics-analysis-netsanet/ --acl public-read --profile netsanet_personal
  wget https://raw.githubusercontent.com/gnetsanet/crispedit/master/bin/msa.min.js
  """
}

