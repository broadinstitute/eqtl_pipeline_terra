FROM python:3.10.6
COPY src/python/qc_plots.py .
COPY src/python/filter.py .
COPY src/python/normalize.py .
COPY src/python/cbc_modify.py .
COPY src/python/peer_selection.py .
COPY src/python/pseudobulk.py .
COPY src/python/X_expression.py .
COPY src/requirements.txt .
RUN pip3 install -r requirements.txt
