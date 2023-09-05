process SAMTOOLS_FAIDX {

    container 'quay.io/biocontainers/samtools:1.16.1--h6899075_1'

    tag "${fasta}"

    input:
    path(fasta)

    output:
    tuple path(fasta),path(fai), emit: fasta
    path("versions.yml"), emit: versions

    script:
    fai = fasta + ".fai"

    """
    samtools faidx $fasta > $fai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

}

