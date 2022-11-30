A Metagenomic Screening of Soil Microbiome
==========================================

A project for IV110 course at FI MUNI.

Authors: Viky, David, Simon

# How to run

We use a
[mamba](https://mamba.readthedocs.io/en/latest/installation.html)/
[conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html)
virtual environment. It should be possible to use `conda` instead of `mamba`,
but we recommend to install
[mambaforge](https://github.com/conda-forge/miniforge#mambaforge).
Then You can create and activate the environment:

```
mamba env create -f IV110.yml
mamba activate IV110
```

For basecalling, we use ONT `guppy`, which has to be installed by Yourself
as it cannot be included in a `conda` environment.

It may be useful to look into the `config.yml` file and set some names to more
appropriate values for You. An argument `-C`/`--config` is to be used for that.
E.g. to download the `.fast5` files into this local repository, say folder
`./data`, instead of (default) global folder `/data`:

```
snakemake -c1 data/barcode03 -C raw_data_local=data
```

When running the worklow, don't forget to add `--use-conda` flag to your workflow execution command to set up conda environments for used tools (for more information, see [Integrated Package Managment](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html#integrated-package-management)), and specify Your
username to login into faculty servers, e.g.:

```
snakemake -c4 --use-conda -C username={Your xlogin}
```

Then login into the `hedron` server and run `MEGAN` to analyse
`~/vargac/IV110/{barcode}/aligned.daa` files.

# How to contribute

After adding new dependencies please run:
```
mamba env export --no-builds --from-history | grep -v "prefix" > IV110.yml
```
And then hand-curate the `.yml` file as it may include unused channels
and, on the other hand, not include the used ones.

# Internal notes

| Sample | Place       | Depth | Flow cell | Bar code |
|--------|-------------|-------|-----------|----------|
| B1     | Brno        | 5cm   | big       | 3        |
| B2     | Brno        | 20cm  | big       | 4        |
| D1     | Bretejovce  | 5cm   | big       | 7        |
| D2     | Bretejovce  | 20cm  | big       | 8        |


# Workflow

## MinION data preprocessing
1. Basecalling 
    - Guppy-gpu
2. Quality control
    - [MinIONQC](https://github.com/roblanf/minion_qc)
3. Filtering, trimming, adapter removal
    - [Porechop](https://github.com/rrwick/Porechop)
4. Genome assembly
    - [Flye](https://github.com/fenderglass/Flye)
    - [medaka](https://github.com/nanoporetech/medaka) [error correction]

