ARG PYTHON_VERSION
FROM python:${PYTHON_VERSION} as aws-cli-installer
ARG AWS_CLI_VERSION

WORKDIR /tmp
COPY ./aws-cli-gpg.pub /tmp/aws-cli-gpg.pub
RUN set -x \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-$AWS_CLI_VERSION.zip" -o "/tmp/awscliv2.zip" \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-$AWS_CLI_VERSION.zip.sig" -o "/tmp/awscliv2.sig" \
  && gpg --import /tmp/aws-cli-gpg.pub \
  && gpg --verify /tmp/awscliv2.sig /tmp/awscliv2.zip \
  && unzip /tmp/awscliv2.zip \
  && /tmp/aws/install --bin-dir /aws-cli-bin/

FROM python:${PYTHON_VERSION}

RUN set -x \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    zip \
    unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# also install pylint
COPY ./requirements.txt /tmp/requirements.txt
RUN set +x \
  && pip install --no-cache -r /tmp/requirements.txt

COPY --from=aws-cli-installer /usr/local/aws-cli /usr/local/aws-cli
COPY --from=aws-cli-installer /aws-cli-bin/ /usr/local/bin/
