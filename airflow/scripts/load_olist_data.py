import os
import sys
import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
from pathlib import Path
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class OlistDataLoader:

    def __init__(self):
        self.data_dir = Path(os.getenv('DATA_DIR', '/opt/airflow/data/raw'))
        self.conn_params = {
            'host': os.getenv('WH_HOST', 'postgres_wh'),
            'user': os.getenv('WH_USER', 'shopflow'),
            'password': os.getenv('WH_PASSWORD', 'shopflow_pass'),
            'database': os.getenv('WH_DB', 'shopflow_warehouse'),
            'port': 5432
        }
        self.connection = None

        self.file_table_mapping = {
            'olist_customers_dataset.csv': 'raw_customers',
            'olist_orders_dataset.csv': 'raw_orders',
            'olist_order_items_dataset.csv': 'raw_order_items',
            'olist_order_payments_dataset.csv': 'raw_order_payments',
            'olist_products_dataset.csv': 'raw_products',
            'olist_sellers_dataset.csv': 'raw_sellers',
            'olist_geolocation_dataset.csv': 'raw_geolocation',
            'product_category_name_translation.csv': 'raw_product_category_translation',
            'olist_order_reviews_dataset.csv': 'raw_order_reviews'
        }

    def connect(self):
        try:
            self.connection = psycopg2.connect(**self.conn_params)
            logger.info(f"Connected to database: {self.conn_params['database']}")
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            raise

    def disconnect(self):
        if self.connection:
            self.connection.close()
            logger.info("Database connection closed")

    def truncate_table(self, table_name):
        try:
            cursor = self.connection.cursor()
            cursor.execute(f"TRUNCATE TABLE {table_name} CASCADE;")
            self.connection.commit()
            cursor.close()
            logger.info(f"Truncated table: {table_name}")
        except Exception as e:
            logger.error(f"Failed to truncate {table_name}: {e}")
            self.connection.rollback()
            raise

    def load_csv_to_table(self, csv_file, table_name):
        file_path = self.data_dir / csv_file

        if not file_path.exists():
            logger.warning(f"File not found: {file_path} - skipping")
            return 0

        try:
            logger.info(f"Loading {csv_file} into {table_name}...")

            df = pd.read_csv(file_path, encoding='utf-8', errors='replace')
            logger.info(f"Read {len(df)} rows from {csv_file}")

            df.columns = df.columns.str.lower()

            df = df.rename(
                columns={
                    "product_name_lenght": "product_name_length",
                    "product_description_lenght": "product_description_length",
                }
            )

            df = df.where(pd.notnull(df), None)

            columns = df.columns.tolist()
            columns_str = ', '.join(columns)
            placeholders = ', '.join(['%s'] * len(columns))

            insert_query = f"""
                INSERT INTO {table_name} ({columns_str})
                VALUES %s
                ON CONFLICT DO NOTHING
            """

            data_tuples = [tuple(row) for row in df.values]

            cursor = self.connection.cursor()
            execute_values(cursor, insert_query, data_tuples, page_size=1000)
            self.connection.commit()
            cursor.close()

            logger.info(f"Successfully loaded {len(df)} rows into {table_name}")
            return len(df)

        except Exception as e:
            logger.error(f"Failed to load {csv_file}: {e}")
            self.connection.rollback()
            raise

    def load_all_files(self, truncate_first=True):
        total_rows = 0
        successful_loads = 0
        failed_loads = []

        for csv_file, table_name in self.file_table_mapping.items():
            try:
                if truncate_first:
                    self.truncate_table(table_name)

                rows_loaded = self.load_csv_to_table(csv_file, table_name)
                total_rows += rows_loaded
                successful_loads += 1

            except Exception as e:
                logger.error(f"Error loading {csv_file}: {e}")
                failed_loads.append(csv_file)
                continue

        logger.info(f"\n{'='*60}")
        logger.info(f"Data loading complete!")
        logger.info(f"Files processed: {successful_loads}/{len(self.file_table_mapping)}")
        logger.info(f"Total rows loaded: {total_rows:,}")
        logger.info(f"{'='*60}")

        if failed_loads:
            raise RuntimeError(
                f"Failed to load {len(failed_loads)} file(s): {', '.join(failed_loads)}"
            )

        if successful_loads == 0 or total_rows == 0:
            raise RuntimeError(
                "No data loaded into raw tables. Verify schema creation and CSV files."
            )

    def verify_data(self):
        logger.info("\nVerifying data load...")
        cursor = self.connection.cursor()

        for table_name in self.file_table_mapping.values():
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                count = cursor.fetchone()[0]
                logger.info(f"  {table_name}: {count:,} rows")
            except Exception as e:
                logger.error(f"  {table_name}: Error - {e}")

        cursor.close()


def main():
    logger.info("Starting Olist data load process...")

    loader = OlistDataLoader()

    try:
        loader.connect()

        loader.load_all_files(truncate_first=True)

        loader.verify_data()

    except Exception as e:
        logger.error(f"Data load failed: {e}")
        sys.exit(1)

    finally:
        loader.disconnect()

    logger.info("Data load process completed successfully!")
    sys.exit(0)


if __name__ == '__main__':
    main()
