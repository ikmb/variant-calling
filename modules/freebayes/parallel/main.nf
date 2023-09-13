process FREEBAYES_PARALLEL {

    label 'long_parallel'

    container 'quay.io/biocontainers/freebayes:1.3.6--hbfe0e7f_2'

    publishDir "${params.outdir}/JOINT_CALLS/FREEBAYES", mode: 'copy'

    input:
    path(bams)
    path(bais)
    tuple path(fasta),path(fai),path(dict)

    output:
    path(vcf), emit: vcf
    path("versions.yml"), emit: versions

    script:
    prefix = "freebayes-joint_calling-" + params.run_name
    vcf =  prefix + ".vcf.gz"
    def options = params.freebayes_options

    """ 
    freebayes-parallel <(fasta_generate_regions.py $fai 10000) ${task.cpus} -f $fasta \\
        $options \\
        --genotype-qualities \\
        --min-mapping-quality 20 $bams > ${prefix}.vcf

    bgzip ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freebayes: \$(echo \$(freebayes --version 2>&1) | sed 's/version:\s*v//g' )
    END_VERSIONS

    
    """
}