# syntax=docker/dockerfile:experimental
FROM quay.io/unstructured-io/base-images:rocky9.2-8@sha256:68b11677eab35ea702cfa682202ddae33f2053ea16c14c951120781a2dcac1b2 as base

ARG PIP_VERSION
ARG PIPELINE_PACKAGE

# Set up environment
ENV HOME /root

ENV PYTHONPATH="${PYTHONPATH}:${HOME}"
ENV PATH="/root/.local/bin:${PATH}"

FROM base as python-deps
COPY requirements/base.txt requirements-base.txt
RUN python3.10 -m pip install pip==${PIP_VERSION} \
  && dnf -y groupinstall "Development Tools" \
  && pip3.10 install --no-cache -r requirements-base.txt \
  && dnf -y groupremove "Development Tools" \
  && dnf clean all \
  && ln -s /root/.local/bin/pip3.10 /usr/local/bin/pip3.10 || true

FROM python-deps as model-deps
COPY scripts/hi_res_model_initialize.py hi_res_model_initialize.py
RUN python3.10 -m pip install nltk && \
  python3.10 -c "import nltk; nltk.download('punkt')" && \
  python3.10 -c "import nltk; nltk.download('averaged_perceptron_tagger')"

FROM model-deps as code
COPY CHANGELOG.md CHANGELOG.md
COPY logger_config.yaml logger_config.yaml
COPY prepline_${PIPELINE_PACKAGE}/ prepline_${PIPELINE_PACKAGE}/
COPY exploration-notebooks exploration-notebooks
COPY scripts/app-start.sh scripts/app-start.sh

ENTRYPOINT ["scripts/app-start.sh"]
EXPOSE 8000
