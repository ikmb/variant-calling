# Usage information

This pipeline is designed to perform variant calling on WGS data, given a reference genome. The basic workflow follows established best-practices and is thus similar to other projects
such as our [exome pipeline](https://github.com/ikmb/exome-seq) or our [whole-genome pipeline](https://github.com/ikmb/deepvariant). However, this particular pipeline does not assume a specific reference but allows users to provide their assembly of choice in FASTA format. The overall workflow is also a bit slimmed down and includes fewer downstream processing such as annotation etc. 

## Basic execution

To run this pipeline, the following syntax is recommended:

```
nextflow run ikmb/variant-calling --samples samples.csv --fasta my_genome.fa --tools deepvariant
```

## Options

### `--samples`

The sample sheet contains information about the location of sequencing data as well as necessary information about the sample id and metadata required to build correctly formatted read group information. The basic format must follow the example below:

```
sample_id,library_id,readgroup_id,R1,R2
MySample,I33978-L2,HHNVKDRXX.2.NA24143_I33978-L2,/path/to/R1,/path/to/R2
```

For samples with multiple sets of paired-end read files, merging of the BAM files will be performed automatically prior to deduplication and variant calling. Do not concatenate the reads beforehand, or you will destroy potentially important readgroup information!

### `--fasta`

The location of reference genome to map against in FASTA format. Can be gzipped (.gz) - but will be decompressed inside the pipeline. 

### `--tools`

A list of variant callers to use. Valid options are:

* [Deepvariant](https://github.com/google/deepvariant) (deepvariant)
* [Freebayes](https://github.com/freebayes/freebayes) (freebayes)

### `--joint_calling` [ default: false]

Perform joint-calling of samples in addition to single-sample variant calling. Note that this option is very slow when combined with Freebayes on larger genomes and/or many samples. 
