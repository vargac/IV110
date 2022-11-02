configfile: "config.yml"

rule download:
    output:
        directory(f"{config['raw_data_local']}{{barcode}}")
    params:
        remote_path=lambda wildcards:
            f"{config['raw_data_remote']}/{wildcards.barcode}"
    shell:
        "mkdir -p `dirname {output}` && "
        "echo -n 'Enter faculty xlogin: ' && read user && "
        "scp -r -o \"ProxyJump $user@aisa.fi.muni.cz\" "
        "$user@adonis.fi.muni.cz:{params.remote_path} "
        "{output}"
