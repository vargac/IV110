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

# How to contribute

After adding new dependencies please run:
```
mamba env export --no-builds | grep -v "prefix" > IV110.yml
```
