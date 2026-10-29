FROM apache/airflow:2.8.1-python3.11

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

RUN pip install --no-cache-dir \
    dbt-core==1.7.8 \
    dbt-postgres==1.7.8 \
    pandas==2.2.0 \
    psycopg2-binary==2.9.9 \
    python-dotenv==1.0.1

USER airflow
