ARG PYTHON_VERSION
FROM python:${PYTHON_VERSION}

COPY ./requirements.txt /tmp/requirements.txt
RUN set -x \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    zip \
    unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && pip install --no-cache --progress-bar off -r /tmp/requirements.txt
