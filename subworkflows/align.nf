include { BWA2_MEM }                            from "./../modules/bwa2/align/main"
include { SAMTOOLS_MERGE as MERGE_MULTI_LANE }  from "./../modules/samtools/merge/main" 
include { SAMTOOLS_INDEX as BAM_INDEX }         from "./../modules/samtools/index/main"
include { SAMTOOLS_MARKDUP }                    from './../modules/samtools/markdup/main'
include { SAMTOOLS_BAM2CRAM }                   from "./../modules/samtools/bam2cram"

ch_aligned_bams     = Channel.from([])
ch_versions         = Channel.from([])
ch_reports          = Channel.from([])

workflow ALIGN {

    take:
    reads
    bwa_index
    genome

    main:

    BWA2_MEM(
        reads,
        bwa_index.collect(),
        genome.map {f,i,d -> d }.collect()
    )

    ch_versions         = ch_versions.mix(BWA2_MEM.out.versions)
    ch_aligned_bams     = BWA2_MEM.out.bam

    bam_mapped = ch_aligned_bams.map { meta, bam ->
        new_meta = [:]
        new_meta.sample_id = meta.sample_id
        def groupKey = meta.sample_id
        tuple( groupKey, new_meta, bam)
    }.groupTuple(by: [0,1]).map { g ,new_meta ,bam -> [ new_meta, bam ] }
            
    bam_mapped.branch {
        single:   it[1].size() == 1
        multiple: it[1].size() > 1
    }.set { bam_to_merge }

    MERGE_MULTI_LANE( bam_to_merge.multiple )

    ch_versions         = ch_versions.mix(MERGE_MULTI_LANE.out.versions)

    BAM_INDEX(
        MERGE_MULTI_LANE.out.bam.mix( bam_to_merge.single )
    )

    SAMTOOLS_MARKDUP(
        BAM_INDEX.out.bam,
        genome.collect()
    )

    ch_reports = ch_reports.mix(SAMTOOLS_MARKDUP.out.report)

    SAMTOOLS_BAM2CRAM(
        SAMTOOLS_MARKDUP.out.bam,
        genome.collect()
    )
    
    emit:
    cram = SAMTOOLS_BAM2CRAM.out.cram
    bam = BAM_INDEX.out.bam
    reports = ch_reports
    versions = ch_versions

}