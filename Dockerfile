FROM nfcore/base
LABEL authors="Netsanet Gebremedhin" \
      description="Docker image containing all requirements for nf-core/crispedit pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-crispedit-1.0dev/bin:$PATH
