process DEEPVARIANT {

    tag "${meta.sample_id}"

    label 'long_parallel'

    container 'google/deepvariant:1.5.0'

    publishDir "${params.outdir}/${meta.sample_id}/DEEPVARIANT", mode: 'copy'

    input:
    tuple val(meta), path(bam),path(bai)
    tuple path(fasta),path(fai),path(dict)

    output:
    path(dv_gvcf), emit: gvcf
    tuple val(meta),path(dv_vcf), emit: vcf
    path("versions.yml"), emit: versions

    script:
    dv_gvcf = meta.sample_id + "-deepvariant.g.vcf.gz"
    dv_vcf =  meta.sample_id + "-deepvariant.vcf.gz"

    """
    /opt/deepvariant/bin/run_deepvariant \
        --model_type=WES \
        --ref=$fasta \
        --reads $bam \
        --output_vcf=$dv_vcf \
        --output_gvcf=$dv_gvcf \
        --num_shards=${task.cpus} \

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deepvariant: \$(echo \$(/opt/deepvariant/bin/run_deepvariant --version) | sed 's/^.*version //; s/ .*\$//' )
    END_VERSIONS
    """
}

