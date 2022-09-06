FROM python:latest
COPY src/python/plot.py .
COPY src/python/filter.py .
COPY src/python/normalize.py .
COPY src/python/cbc_modify.py .
COPY src/python/peer_selection.py .
COPY src/python/pseudobulk.py .
COPY src/requirements.txt .
RUN pip3 install -r requirements.txt
