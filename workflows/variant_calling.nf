
ch_input            = Channel.fromPath(params.samples)
ch_fa               = Channel.fromPath(file(params.fasta, checkIfExists: true) )

include { INPUT_CHECK }         from '../modules/input_check'
include { GUNZIP }              from '../modules/gunzip/main'
include { FASTP }               from '../modules/fastp/main'
include { BWA2_MEM_INDEX }      from '../modules/bwa2/index/main'
include { ALIGN }               from '../subworkflows/align'
include { SAMTOOLS_FAIDX }      from "../modules/samtools/faidx/main"
include { DEEPVARIANT }         from '../modules/deepvariant/main'
include { GLNEXUS }             from '../modules/glnexus/main'
include { FREEBAYES }           from '../modules/freebayes/main'
include { FREEBAYES_PARALLEL }  from '../modules/freebayes/parallel/main'
include { SOFTWARE_VERSIONS }   from '../modules/software_versions'
include { MULTIQC }             from './../modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'
include { SAMTOOLS_DICT }       from './../modules/samtools/dict/main'
include { TABIX }               from './../modules/htslib/tabix/main'
include { BCFTOOLS_STATS }      from './../modules/bcftools/stats/main'

ch_versions         = Channel.from([])
multiqc_files       = Channel.from([])
ch_vcfs             = Channel.from([])

tools = params.tools ? params.tools.split(',').collect{it.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '')} : []

if (tools.isEmpty()) {
    log.info "You have not provided any variant callers via --tools; will only compute alignments!"
}

workflow VARIANT_CALLING {
	
    main:

    INPUT_CHECK(ch_input)
	
    // trim reads to remove adapters
    FASTP(
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)
    multiqc_files = multiqc_files.mix(FASTP.out.json)

    // if the assembly is gzipped, decompress first
    if ( file(params.fasta).getExtension() == "gz" ) {
        GUNZIP(
            ch_fa
        )
        ch_fasta = GUNZIP.out.decompressed
    } else {
        ch_fasta = ch_fa
    }

    // Index the assembly to be used in variant calling
    SAMTOOLS_FAIDX(
        ch_fasta
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)

    // Build sequence dictionary from assembly
    SAMTOOLS_DICT(
        ch_fasta
    )

    // Merge sequence dictionary with fasta and fasta index, makes [ fasta, fai, dict ]
    SAMTOOLS_FAIDX.out.fasta.map { f,i -> [ "A", f, i ]}.join(
        SAMTOOLS_DICT.out.dict.map { d -> [ "A", d ]}
    ).map { x,f,i,d -> [ f,i,d ]}
    .set { ch_genome }

    // build a mapping index for the genome
    BWA2_MEM_INDEX(
        ch_fasta
    )
    ch_versions = ch_versions.mix(BWA2_MEM_INDEX.out.versions)

    // align reads to the genome index
    ALIGN(
        FASTP.out.reads,
        BWA2_MEM_INDEX.out.bwa_index,
        ch_genome
    )
    ch_versions = ch_versions.mix(ALIGN.out.versions)
    multiqc_files = multiqc_files.mix(ALIGN.out.reports)

    // call variants using Deepvariant
    if ('deepvariant' in tools ) {

        DEEPVARIANT(
            ALIGN.out.bam,
            ch_genome.collect()
        )

        ch_vcfs = DEEPVARIANT.out.vcf
        ch_versions = ch_versions.mix(DEEPVARIANT.out.versions)

        if (params.joint_calling) {

            GLNEXUS(
                DEEPVARIANT.out.gvcf.collect()
            )
            //ch_vcfs = ch_vcfs.mix(GLNEXUS.out.vcf)
            ch_versions = ch_versions.mix(GLNEXUS.out.versions)
        }

    }

    // call variants using Freebayes
    if ('freebayes' in tools) {

        FREEBAYES(
            ALIGN.out.bam,
            ch_genome.collect()
        )

        ch_vcfs = ch_vcfs.mix(FREEBAYES.out.vcf)

        ch_versions = ch_versions.mix(FREEBAYES.out.versions)

        if (params.joint_calling) {

            FREEBAYES_PARALLEL(
                ALIGN.out.bam.map { m,b,i -> b}.collect(),
                ALIGN.out.bam.map { m,b,i -> i}.collect(),
                ch_genome.collect()
            )

            //ch_vcfs = ch_vcfs.mix(FREEBAYES_PARALLEL.out.vcf)
        }

    }

    TABIX(
        ch_vcfs
    )
    ch_versions = ch_versions.mix(TABIX.out.versions)

    BCFTOOLS_STATS(
        TABIX.out.vcf
    )
    ch_versions = ch_versions.mix(BCFTOOLS_STATS.out.versions)
    multiqc_files = multiqc_files.mix(BCFTOOLS_STATS.out.stats)
	
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
	
    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect()
    )
    
    emit:
    qc = MULTIQC.out.report
	
}
