configfile: "config.yml"

BASECALLED_DIR = config['basecalled_local']
OUTPUT_DIR = config['outputs_local']
# BARCODES = ["barcode03", "barcode04", "barcode07", "barcode08"]
BARCODES = ["barcode03"]


rule all:
    input:
        expand(f"{OUTPUT_DIR}/minionqc/{{barcode}}", barcode=BARCODES),
        expand(f"{OUTPUT_DIR}/medaka/{{barcode}}/consensus.fasta", barcode=BARCODES)


rule download:
    output:
        directory(f"{config['raw_data_local']}/{{barcode}}")
    params:
        remote_path=lambda wildcards:
            f"{config['raw_data_remote']}/{wildcards.barcode}"
    shell:
        "mkdir -p `dirname {output}` && "
        "echo -n 'Enter faculty xlogin: ' && read user && "
        "scp -r -o \"ProxyJump $user@aisa.fi.muni.cz\" "
        "$user@adonis.fi.muni.cz:{params.remote_path} "
        "{output}"


# TODO check if it works, guppy has to be installed?
rule basecalling:
    input:
        directory(f"{config['raw_data_local']}/{{barcode}}")
    output:
        directory(f"{BASECALLED_DIR}/{{barcode}}")
    shell:
        "mkdir -p `dirname {output}`  && "
        "guppy_basecaller --input_path {input} --save_path {output} --flowcell FLO-MIN106 --kit SQK-RBK004"

rule merge_fastq:
    input:
        f"{BASECALLED_DIR}/{{barcode}}/pass"
    output:
        f"{OUTPUT_DIR}/merged_fastq/{{barcode}}/reads.fastq"
    shell:
        "cat {input}/*.fastq > {output}"


rule compress_fastq:
    input:
        f"{OUTPUT_DIR}/merged_fastq/{{barcode}}/reads.fastq"
    output:
        f"{OUTPUT_DIR}/merged_fastq/{{barcode}}/reads.fastq.gz"
    conda:
        "envs/htslib.yaml"
    shell:
        "bgzip {input}"


rule minionqc:
    input:
        f"{BASECALLED_DIR}/{{barcode}}/sequencing_summary.txt"
    output:
        directory(f"{OUTPUT_DIR}/minionqc/{{barcode}}")
    params:
        output_dir=f"{OUTPUT_DIR}/minionqc"
    conda:
        "envs/minionqc.yaml"
    shell:
        "Rscript  ${{PATH%%/bin:*}}/bin/MinIONQC.R -i {input} -o {params.output_dir}"


rule porechop:
    input:
        f"{OUTPUT_DIR}/merged_fastq/{{barcode}}/reads.fastq.gz"
    output:
        f"{OUTPUT_DIR}/porechop/{{barcode}}/reads-porechop.fastq.gz"
    conda:
        "envs/porechop.yaml"
    shell:
        "porechop -i {input} -o {output} --discard_middle"


rule nanofilt:
    input:
        f"{OUTPUT_DIR}/porechop/{{barcode}}/reads-porechop.fastq.gz"
    output:
        f"{OUTPUT_DIR}/nanofilt/{{barcode}}/reads-nanofilt.fastq.gz"
    conda:
        "envs/nanofilt.yaml"
    shell:
        "gunzip -c {input} | NanoFilt -q 8 | gzip > {output}"


rule unicycler:
    input:
        f"{OUTPUT_DIR}/nanofilt/{{barcode}}/reads-nanofilt.fastq.gz"
    output:
        f"{OUTPUT_DIR}/unicycler/{{barcode}}/assembly.fasta"
    params:
        output_dir=f"{OUTPUT_DIR}/unicycler/{{barcode}}"
    conda:
        "envs/unicycler.yaml"
    shell:
        "unicycler -l {input} -o {params.output_dir}"


rule medaka:
    input:
        assembly=f"{OUTPUT_DIR}/unicycler/{{barcode}}/assembly.fasta",
        raw_reads=f"{OUTPUT_DIR}/merged_fastq/{{barcode}}/reads.fastq.gz"
    output:
        f"{OUTPUT_DIR}/medaka/{{barcode}}/consensus.fasta"
    params:
        output_dir=f"{OUTPUT_DIR}/medaka/{{barcode}}"
    conda:
        "envs/medaka.yaml"
    shell:
        "medaka_consensus -i {input.raw_reads} -d {input.assembly} -o {params.output_dir}"
        
