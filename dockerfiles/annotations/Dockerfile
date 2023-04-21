FROM python:3.10.6
COPY src/python/annotate_ldsc.py .
COPY src/python/annotate_peaks.py .

COPY src/requirements.txt .
RUN pip3 install -r requirements.txt

# set environment variables
ENV bedtools_version 2.30.0

# install bedtools
WORKDIR /usr/local/bin
RUN curl -SL https://github.com/arq5x/bedtools2/archive/v${bedtools_version}.tar.gz \
    > v${bedtools_version}.tar.gz
RUN tar -xzvf v${bedtools_version}.tar.gz
WORKDIR /usr/local/bin/bedtools2-${bedtools_version}
RUN make
RUN ln -s /usr/local/bin/bedtools2-${bedtools_version}/bin/bedtools /usr/local/bin/bedtools
