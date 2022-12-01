configfile: "config.yml"

OUTPUT_DIR = config['outputs_local']
BARCODES = ["barcode03", "barcode04", "barcode07", "barcode08"]
JUMP = f"{config['username']}@aisa.fi.muni.cz"


rule all:
    input:
        expand(f"{OUTPUT_DIR}/minionqc/{{barcode}}", barcode=BARCODES),
        expand(f"{OUTPUT_DIR}/megan/{{barcode}}/aligned.daa", barcode=BARCODES)

rule download:
    output:
        directory(f"{config['raw_data_local']}/{{barcode}}")
    params:
        remote_path=lambda wildcards:
            f"{config['raw_data_remote']}/{wildcards.barcode}"
    shell:
        "mkdir -p `dirname {output}` && "
        "scp -r -o \"ProxyJump {JUMP}\" "
        f"{config['username']}@adonis.fi.muni.cz:{{params.remote_path}} "
        "{output}"


rule basecalling:
    input:
        f"{config['raw_data_local']}/{{barcode}}"
    params:
        prefix=lambda wildcards, output: output[0][:-5]
    output:
        directory(f"{OUTPUT_DIR}/guppy/{{barcode}}/pass"),
        f"{OUTPUT_DIR}/guppy/{{barcode}}/sequencing_summary.txt"
    shell:
        "guppy_basecaller --input_path {input} --save_path {params.prefix} --flowcell FLO-MIN106 --kit SQK-RBK004"


rule merge_fastq:
    input:
        f"{OUTPUT_DIR}/guppy/{{barcode}}/pass"
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
        f"{OUTPUT_DIR}/guppy/{{barcode}}/sequencing_summary.txt"
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


rule flye:
    input:
        f"{OUTPUT_DIR}/porechop/{{barcode}}/reads-porechop.fastq.gz"
    output:
        f"{OUTPUT_DIR}/flye/{{barcode}}/assembly.fasta"
    params:
        output_dir=f"{OUTPUT_DIR}/flye/{{barcode}}"
    conda:
        "envs/flye.yaml"
    shell:
        "flye --nano-raw {input} -o {params.output_dir} --meta --threads 4"


rule medaka:
    input:
        assembly=f"{OUTPUT_DIR}/flye/{{barcode}}/assembly.fasta",
        raw_reads=f"{OUTPUT_DIR}/porechop/{{barcode}}/reads-porechop.fastq.gz"
    output:
        f"{OUTPUT_DIR}/medaka/{{barcode}}/consensus.fasta"
    params:
        output_dir=f"{OUTPUT_DIR}/medaka/{{barcode}}"
    conda:
        "envs/medaka.yaml"
    shell:
        "medaka_consensus -i {input.raw_reads} -d {input.assembly} -o {params.output_dir}"

rule diamond:
    input:
        f"{OUTPUT_DIR}/medaka/{{barcode}}/consensus.fasta"
    output:
        f"{OUTPUT_DIR}/diamond/{{barcode}}/aligned.daa"
    params:
        wd="vargac/IV110/{barcode}"
    shell:
        "ssh -J {JUMP} hedron "
            "mkdir -p {params.wd} && "
        "scp -o \"ProxyJump {JUMP}\" "
            "{input} hedron:{params.wd}/ && "
        "ssh -J {JUMP} hedron "
            "diamond blastx -q {params.wd}/consensus.fasta "
            "-d /mnt/nas/biodata/nr.dmnd -o {params.wd}/aligned.daa "
            "-F 15 -f 100 --range-culling --top 10 -p 4 && "
        "mkdir -p $(dirname {output}) && "
        "scp -o \"ProxyJump {JUMP}\" "
            "hedron:{params.wd}/aligned.daa {output}"

rule meganize:
    input:
        f"{OUTPUT_DIR}/diamond/{{barcode}}/aligned.daa"
    output:
        f"{OUTPUT_DIR}/megan/{{barcode}}/aligned.daa"
    params:
        wd="vargac/IV110/{barcode}"
    shell:
        "ssh -J {JUMP} hedron "
            "mkdir -p {params.wd} && "
        "scp -o \"ProxyJump {JUMP}\" "
            "{input} hedron:{params.wd}/ && "
        "ssh -J {JUMP} hedron "
            f"{config['meganizer']} -i {{params.wd}}/aligned.daa "
            f"-mdb {config['megan_map']} --longReads && "
        "mkdir -p $(dirname {output}) && "
        "scp -o \"ProxyJump {JUMP}\" "
            "hedron:{params.wd}/aligned.daa {output}"
