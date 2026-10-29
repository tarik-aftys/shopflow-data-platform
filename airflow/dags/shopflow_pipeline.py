import os
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

DBT_PROJECT_DIR = os.getenv("DBT_PROJECT_DIR", "/opt/dbt/shopflow_dbt")
DBT_PROFILES_DIR = os.getenv("DBT_PROFILES_DIR", "/opt/dbt/shopflow_dbt")
DATA_DIR = os.getenv("DATA_DIR", "/opt/airflow/data/raw")
SCRIPTS_DIR = os.getenv("SCRIPTS_DIR", "/opt/airflow/scripts")
RAW_SCHEMA_FILE = os.getenv("RAW_SCHEMA_FILE", "/sql/raw_schema.sql")

def _wh_env():
    return {
        "WH_HOST": os.getenv("WH_HOST", "postgres_wh"),
        "WH_USER": os.getenv("WH_USER", "shopflow"),
        "WH_PASSWORD": os.getenv("WH_PASSWORD", "shopflow_pass"),
        "WH_DB": os.getenv("WH_DB", "shopflow_warehouse"),
        "PYTHONUNBUFFERED": "1",
    }

def _dbt_env():
    return {
        "POSTGRES_HOST": os.getenv("POSTGRES_HOST", "postgres_wh"),
        "POSTGRES_USER": os.getenv("POSTGRES_USER", "shopflow"),
        "POSTGRES_PASSWORD": os.getenv("POSTGRES_PASSWORD", "shopflow_pass"),
        "POSTGRES_DB": os.getenv("POSTGRES_DB", "shopflow_warehouse"),
        "PYTHONUNBUFFERED": "1",
    }

with DAG(
    dag_id="shopflow_pipeline",
    default_args=default_args,
    description="ShopFlow Analytics ELT pipeline — Olist Dataset → dbt → Star Schema",
    schedule="0 6 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["shopflow", "elt", "dbt", "olist", "production"],
) as dag:

    start_pipeline = EmptyOperator(
        task_id="start_pipeline",
    )

    check_csv_files = BashOperator(
        task_id="task_1_1_check_csv_files",
        bash_command=f"""
        echo "Checking for Olist dataset CSV files in {DATA_DIR}..."
        
        if [ ! -d "{DATA_DIR}" ]; then
            echo "ERROR: Data directory {DATA_DIR} does not exist!"
            exit 1
        fi
        
        file_count=$(ls {DATA_DIR}/*.csv 2>/dev/null | wc -l)
        
        if [ $file_count -eq 0 ]; then
            echo "WARNING: No CSV files found in {DATA_DIR}"
            echo "Please download the Olist dataset from Kaggle and place CSV files in {DATA_DIR}"
            echo "See data/raw/README.md for instructions"
            exit 1
        fi
        
        echo "Found $file_count CSV files"
        ls -lh {DATA_DIR}/*.csv
        """,
    )

    create_raw_schema = BashOperator(
        task_id="task_1_2_create_raw_schema",
        bash_command=f"""
        python - <<'PY'
import os
from pathlib import Path
import psycopg2

schema_path = Path("{RAW_SCHEMA_FILE}")
if not schema_path.exists():
    raise FileNotFoundError("Raw schema file not found: " + str(schema_path))

conn = psycopg2.connect(
    host=os.getenv("WH_HOST", "postgres_wh"),
    user=os.getenv("WH_USER", "shopflow"),
    password=os.getenv("WH_PASSWORD", "shopflow_pass"),
    dbname=os.getenv("WH_DB", "shopflow_warehouse"),
    port=5432,
)
try:
    with conn:
        with conn.cursor() as cur:
            cur.execute(schema_path.read_text(encoding="utf-8"))
finally:
    conn.close()

print("Raw schema created/refreshed successfully")
PY
        """,
        env=_wh_env(),
    )
    
    load_raw_tables = BashOperator(
        task_id="task_1_3_load_raw_tables",
        bash_command=f"python {SCRIPTS_DIR}/load_olist_data.py",
        env={**_wh_env(), "DATA_DIR": DATA_DIR},
    )

    dbt_deps = BashOperator(
        task_id="task_2_dbt_deps",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt deps --profiles-dir {DBT_PROFILES_DIR}",
        env=_dbt_env(),
    )

    dbt_run_staging = BashOperator(
        task_id="task_3_run_dbt_staging",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} && \
        dbt run --select staging --profiles-dir {DBT_PROFILES_DIR} && \
        echo "Staging models completed successfully"
        """,
        env=_dbt_env(),
    )

    dbt_run_intermediate = BashOperator(
        task_id="task_4_run_dbt_intermediate",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} && \
        dbt run --select intermediate --profiles-dir {DBT_PROFILES_DIR} && \
        echo "Intermediate models completed successfully"
        """,
        env=_dbt_env(),
    )

    dbt_run_marts = BashOperator(
        task_id="task_5_run_dbt_marts",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} && \
        dbt run --select marts --profiles-dir {DBT_PROFILES_DIR} && \
        echo "Marts models (dimensional schema) completed successfully"
        """,
        env=_dbt_env(),
    )

    dbt_snapshot = BashOperator(
        task_id="task_6_run_dbt_snapshots",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} && \
        dbt snapshot --profiles-dir {DBT_PROFILES_DIR} && \
        echo "Snapshots (SCD Type 2) completed successfully"
        """,
        env=_dbt_env(),
    )

    dbt_test = BashOperator(
        task_id="task_7_run_dbt_tests",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} && \
        dbt test --profiles-dir {DBT_PROFILES_DIR} && \
        echo "All data quality tests passed!"
        """,
        env=_dbt_env(),
    )

    dbt_docs_generate = BashOperator(
        task_id="task_8_generate_dbt_docs",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} && \
        dbt docs generate --profiles-dir {DBT_PROFILES_DIR} && \
        echo "dbt documentation generated successfully"
        echo "To view: dbt docs serve"
        """,
        env=_dbt_env(),
    )

    end_pipeline = EmptyOperator(
        task_id="end_pipeline",
    )

    start_pipeline >> check_csv_files >> create_raw_schema >> load_raw_tables >> dbt_deps
    dbt_deps >> dbt_run_staging >> dbt_run_intermediate >> dbt_run_marts
    dbt_run_staging >> dbt_snapshot >> dbt_run_marts
    dbt_run_marts >> dbt_test >> dbt_docs_generate >> end_pipeline
