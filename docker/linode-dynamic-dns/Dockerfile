FROM arm32v6/python:3.8-alpine

ARG DYNDNS_VERSION

ENV FREQUENCY=900
    # 15 minutes

RUN pip3 install --no-cache-dir linode-dynamic-dns==${DYNDNS_VERSION}

CMD ["linode-dynamic-dns", "-s", "${FREQUENCY}"]