A Metagenomic Screening of Soil Microbiome
==========================================

A project for IV110 course at FI MUNI.

Authors: Viky, David, Simon

# How to run

We use a
![mamba](https://mamba.readthedocs.io/en/latest/installation.html)/
![conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html)
virtual environment. It should be possible to use `conda` instead of `mamba`,
but we recommend to install
![mambaforge](https://github.com/conda-forge/miniforge#mambaforge).
Then You can create and activate the environment:

```
mamba env create -f IV110.yml
mamba activate IV110
```

It may be useful to look into the `config.yml` file and set some names to more
appropriate values for You. An argument `-C`/`--config` is to be used for that.
E.g. to download the `.fast5` files into this local repository, say folder
`./data`, instead of (default) global folder `/data`:

```
snakemake -c1 data/barcode03 -C raw_data_local=data
```

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
