process FREEBAYES {

    tag "${meta.sample_id}"

    label 'long_parallel'

    container 'quay.io/biocontainers/freebayes:1.3.6--hb0f3ef8_7'

    publishDir "${params.outdir}/${meta.sample_id}/FREEBAYES", mode: 'copy'

    input:
    tuple val(meta), path(bam),path(bai)
    tuple path(fasta),path(fai),path(dict)

    output:
    tuple val(meta),path(vcf), emit: vcf
    path("versions.yml"), emit: versions

    script:
    prefix = meta.sample_id + "-freebayes"
    vcf =  prefix + ".vcf.gz"
    def options = params.freebayes_options
    """
    
    freebayes \\
        -f $fasta \\
        $options \\
        --genotype-qualities \\
        --min-mapping-quality 20 \\
        $bam > ${prefix}.vcf

    bgzip ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freebayes: \$(echo \$(freebayes --version 2>&1) | sed 's/version:\s*v//g' )
    END_VERSIONS

    
    """
}