process BWA2_MEM_INDEX {

    container 'quay.io/biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:2cdf6bf1e92acbeb9b2834b1c58754167173a410-0'

    tag "${fasta}"
    
    label 'highmem_serial'

    input:
    path(fasta)

    output:
    tuple path(fasta),path("*.0123"),path("*.amb"),path("*.ann"),path("*.2bit.64"),path("*.pac"), emit: bwa_index
    path("versions.yml"), emit: versions
    
    script:

    """
    bwa-mem2 index $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
    END_VERSIONS
    """

}