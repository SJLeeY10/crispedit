#!/usr/bin/env nextflow
/*
========================================================================================
                         nf-core/crispedit
========================================================================================
 nf-core/crispedit Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/nf-core/crispedit
----------------------------------------------------------------------------------------
*/


def helpMessage() {
    // TODO nf-core: Add to this help message with new command line parameters
    log.info"""
    =======================================================
                                              ,--./,-.
              ___     __   __   __   ___     /,-._.--~\'
        |\\ | |__  __ /  ` /  \\ |__) |__         }  {
        | \\| |       \\__, \\__/ |  \\ |___     \\`-._,-`-,
                                              `._,._,\'

     nf-core/crispedit v${workflow.manifest.version}
    =======================================================

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run nf-core/crispedit --reads '*_R{1,2}.fastq.gz' -profile docker

    Mandatory arguments:
      -profile                      Configuration profile to use. Can use multiple (comma separated)
                                    Available: conda, docker, singularity, awsbatch, test and more.

    Options:
      --singleEnd                   Specifies that the input is single end reads

    References                      If not specified in the configuration file or you wish to overwrite any of the references.
      --fasta                       Path to Fasta reference
      --fastq 						Input FASTQ file

    Other options:
      --outdir                      The output directory where the results will be saved
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    AWSBatch options:
      --awsqueue                    The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion                   The AWS Region for your AWS Batch job to run on
    """.stripIndent()
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

// Show help emssage
if (params.help){
    helpMessage()
    exit 0
}


custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}


if( workflow.profile == 'awsbatch') {
  // AWSBatch sanity checking
  if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
  if (!workflow.workDir.startsWith('s3') || !params.outdir.startsWith('s3')) exit 1, "Specify S3 URLs for workDir and outdir parameters on AWSBatch!"
  // Check workDir/outdir paths to be S3 buckets if running on AWSBatch
  // related: https://github.com/nextflow-io/nextflow/issues/813
  if (!workflow.workDir.startsWith('s3:') || !params.outdir.startsWith('s3:')) exit 1, "Workdir or Outdir not on S3 - specify S3 Buckets for each to run on AWSBatch!"
}

/*
 * Create a channel for input read files
 */

Channel.fromPath(params.fastq)
	.ifEmpty { exit 1, "Interleaved FASTQ file not found: ${params.fastq}" }
	.set { in_fastq }

Channel.fromPath(params.genome)
	.ifEmpty { exit 1, "Reference genome file not found: ${params.genome}" }
	.into { in_reference_for_mapping; in_reference_for_psa }
 


// Header log info
log.info """=======================================================
                                          ,--./,-.
          ___     __   __   __   ___     /,-._.--~\'
    |\\ | |__  __ /  ` /  \\ |__) |__         }  {
    | \\| |       \\__, \\__/ |  \\ |___     \\`-._,-`-,
                                          `._,._,\'

nf-core/crispedit v${workflow.manifest.version}"
======================================================="""
def summary = [:]
summary['Pipeline Name']  = 'nf-core/crispedit'
summary['Pipeline Version'] = workflow.manifest.version
summary['Run Name']     = custom_runName ?: workflow.runName
// TODO nf-core: Report custom parameters here
summary['Reads']        = params.reads
summary['Fasta Ref']    = params.fasta
summary['Data Type']    = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Max Memory']   = params.max_memory
summary['Max CPUs']     = params.max_cpus
summary['Max Time']     = params.max_time
summary['Output dir']   = params.outdir
summary['Working dir']  = workflow.workDir
summary['Container Engine'] = workflow.containerEngine
if(workflow.containerEngine) summary['Container'] = workflow.container
summary['Current home']   = "$HOME"
summary['Current user']   = "$USER"
summary['Current path']   = "$PWD"
summary['Working dir']    = workflow.workDir
summary['Output dir']     = params.outdir
summary['Script dir']     = workflow.projectDir
summary['Config Profile'] = workflow.profile
if(workflow.profile == 'awsbatch'){
   summary['AWS Region'] = params.awsregion
   summary['AWS Queue'] = params.awsqueue
}
if(params.email) summary['E-mail Address'] = params.email
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="


def create_workflow_summary(summary) {
    def yaml_file = workDir.resolve('workflow_summary_mqc.yaml')
    yaml_file.text  = """
    id: 'nf-core-crispedit-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'nf-core/crispedit Workflow Summary'
    section_href: 'https://github.com/nf-core/crispedit'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
        </dl>
    """.stripIndent()

   return yaml_file
}



/*
 * STEP 1 - 
 */
process indexAndMapping {
    tag "${fastq.baseName}"

    input:
    set val(fastq), file(reads) from in_fastq
    set val(genome), file(reference) from in_reference_for_mapping

    output:
    file "*.bam" into aln_file



    script:
    """
    bbmap.sh ref=${genome}
    bbmap.sh in=${fastq} out=${fastq.baseName}.bam
    """
}

process identifyHFR {
    tag "${bam.baseName}"

    input:
    file bam from aln_file

    output:
    file "*.hfr.txt" into hfr_file


    script:
    """
    samtools view ${bam}|awk -F'\t' '{ print \$3"\t"\$4"\t"\$6"\t"\$10 }'|sort|uniq -c|sort -k1,1n|awk '\$1>100' > ${bam.baseName}.hfr.txt
    """
}


process identiyEdits {
  tag "${hfrFile.baseName}"

  input:
  set val(hfrFile), file(hfR) from hfr_file

  output:
  file "*.edits.hfr.txt" into ( processed_hfr, processed_hfr_final_report)

  script:
  """
  cigar2seq.py ${hfrFile} > ${hfrFile.baseName}.edits.hfr.txt
  """
}


process prepAndPerformPSA {
  tag "${processedHfrFile.baseName}"
  publishDir params.outdir, mode: 'copy'

  input:
  set val(processedHfrFile), file(processedHfr) from processed_hfr
  set val(genome), file(reference) from in_reference_for_psa


  output:
  file "*.clustal.out" into clustal_out

  script:
  """
  createPSAFiles.sh ${processedHfrFile} ${genome}
  for psa in \$(cat clustalO_input.txt);
  do
    clustalo  --in=\${psa} > \${psa%.*}.clustal.out 
  done
  """
}

clustal_out
  .toList().flatten()
  .map {
    file -> tuple(file, file.baseName)
  }
  .groupTuple()
  .into { clustal_output_to_upload; clustal_output_to_combine }


process uploadClustalOut {
  tag "${psa_out_file.baseName}"

  echo true

  input:
  set val(psa_out_file), val(psa_out) from clustal_output_to_upload

  script:
  """
  aws s3 cp ${psa_out_file} s3://yten-crispr
  """
}


process combineClustalOut {
  tag "${psa_out_file_comb.baseName}"

  echo true

  input:
  set val(psa_out_file_comb), val(psa_out_comb) from clustal_output_to_combine

  output:
  file("combine.complete.txt") into combine_complete_marker

  script:
  """
  cat ${psa_out_file_comb} >> ${params.outdir}/${params.project_name}.combined.clustal.out
  touch combine.complete.txt
  """
}

process uploadCombinedClustalOut {
  
  input:
  file '*.complete.txt' from combine_complete_marker.collect()

  output:
  file("upload.complete.txt") into upload_complete_marker


  script:
  """
  aws s3 cp ${params.outdir}/${params.project_name}.combined.clustal.out s3://yten-crispr
  aws s3api put-object-acl --bucket yten-crispr --key ${params.project_name}.combined.clustal.out  --acl public-read
  touch upload.complete.txt
  """
}

process createFinalReport {
  
  input:
  file '*.complete.txt' from upload_complete_marker
  file(processedHfrFile2) from processed_hfr_final_report

  output:


  script:
  """
  createReportPackage.sh ${processedHfrFile2} ${params.project_name} ${params.project_name}.combined.clustal.out
  """
}

/*
 * Completion e-mail notification
 */
workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[nf-core/crispedit] Successful: $workflow.runName"
    if(!workflow.success){
      subject = "[nf-core/crispedit] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if(workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if(workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if(workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir" ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (params.email) {
        try {
          if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
          // Try to send HTML e-mail using sendmail
          [ 'sendmail', '-t' ].execute() << sendmail_html
          log.info "[nf-core/crispedit] Sent summary e-mail to $params.email (sendmail)"
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, params.email ].execute() << email_txt
          log.info "[nf-core/crispedit] Sent summary e-mail to $params.email (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File( "${params.outdir}/Documentation/" )
    if( !output_d.exists() ) {
      output_d.mkdirs()
    }
    def output_hf = new File( output_d, "pipeline_report.html" )
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_txt }

    log.info "[nf-core/crispedit] Pipeline Complete"

}
