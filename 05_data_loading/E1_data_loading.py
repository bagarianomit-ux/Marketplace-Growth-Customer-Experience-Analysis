from getpass import getpass
from pathlib import Path
import sys

from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PREPARATION_DIR = PROJECT_ROOT / "03_data_preparation" / "python"
DATA_PATH = PROJECT_ROOT / "Data"

if str(PREPARATION_DIR) not in sys.path:
    sys.path.insert(0, str(PREPARATION_DIR))

from data_preparation import prepare_data


DATABASE_NAME = "marketplace_growth_analysis"
CHUNK_SIZE = 5000

LOAD_ORDER = [
    "customers",
    "products",
    "sellers",
    "category_translation",
    "geolocation",
    "orders",
    "order_items",
    "payments",
    "reviews",
]

EXPECTED_TABLES = set(LOAD_ORDER)


def create_database_engine():
    mysql_password = getpass("Enter MySQL password: ")

    connection_url = URL.create(
        "mysql+mysqlconnector",
        username="root",
        password=mysql_password,
        host="localhost",
        port=3306,
        database=DATABASE_NAME,
    )

    return create_engine(
        connection_url,
        pool_pre_ping=True,
    )


def get_database_tables(engine):
    query = text(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_type = 'BASE TABLE'
        """
    )

    with engine.connect() as connection:
        tables = connection.execute(query).scalars().all()

    return set(tables)


def get_table_row_counts(engine):
    row_counts = {}

    with engine.connect() as connection:
        for table_name in LOAD_ORDER:
            row_counts[table_name] = connection.execute(
                text(f"SELECT COUNT(*) FROM `{table_name}`")
            ).scalar_one()

    return row_counts


def get_insertable_columns(engine, table_name):
    query = text(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = :table_name
          AND extra NOT LIKE '%auto_increment%'
        ORDER BY ordinal_position
        """
    )

    with engine.connect() as connection:
        columns = connection.execute(
            query,
            {"table_name": table_name},
        ).scalars().all()

    return columns


def validate_preload_state(cleaned_datasets, engine):
    cleaned_tables = set(cleaned_datasets)

    if cleaned_tables != EXPECTED_TABLES:
        missing = EXPECTED_TABLES - cleaned_tables
        unexpected = cleaned_tables - EXPECTED_TABLES

        raise RuntimeError(
            "Cleaned datasets do not match the expected tables. "
            f"Missing: {sorted(missing)}; "
            f"Unexpected: {sorted(unexpected)}"
        )

    database_tables = get_database_tables(engine)

    if database_tables != EXPECTED_TABLES:
        missing = EXPECTED_TABLES - database_tables
        unexpected = database_tables - EXPECTED_TABLES

        raise RuntimeError(
            "Database tables do not match the expected schema. "
            f"Missing: {sorted(missing)}; "
            f"Unexpected: {sorted(unexpected)}"
        )

    database_columns = {}

    for table_name in LOAD_ORDER:
        dataframe_columns = list(
            cleaned_datasets[table_name].columns
        )

        insertable_columns = get_insertable_columns(
            engine,
            table_name,
        )

        if set(dataframe_columns) != set(insertable_columns):
            raise RuntimeError(
                f"Column mismatch for {table_name}. "
                f"DataFrame: {dataframe_columns}; "
                f"Database: {insertable_columns}"
            )

        database_columns[table_name] = insertable_columns

    row_counts = get_table_row_counts(engine)

    non_empty_tables = {
        table_name: row_count
        for table_name, row_count in row_counts.items()
        if row_count != 0
    }

    if non_empty_tables:
        raise RuntimeError(
            "Target database is not empty. "
            "Recreate it using D2-D4 before loading. "
            f"Existing rows: {non_empty_tables}"
        )

    return database_columns


def load_table(
    engine,
    table_name,
    dataframe,
    database_columns,
):
    load_dataframe = dataframe[
        database_columns
    ].copy()

    expected_rows = len(load_dataframe)

    print(
        f"Loading {table_name:<22} "
        f"{expected_rows:>10,} rows..."
    )

    with engine.begin() as connection:
        load_dataframe.to_sql(
            name=table_name,
            con=connection,
            if_exists="append",
            index=False,
            chunksize=CHUNK_SIZE,
        )

    with engine.connect() as connection:
        loaded_rows = connection.execute(
            text(
                f"SELECT COUNT(*) "
                f"FROM `{table_name}`"
            )
        ).scalar_one()

    if loaded_rows != expected_rows:
        raise RuntimeError(
            f"Row-count mismatch for {table_name}: "
            f"expected {expected_rows:,}, "
            f"loaded {loaded_rows:,}"
        )

    print(
        f"Loaded  {table_name:<22} "
        f"{loaded_rows:>10,} rows"
    )


def main():
    if not DATA_PATH.exists():
        raise FileNotFoundError(
            f"Data directory not found: {DATA_PATH}"
        )

    print("Preparing cleaned datasets...")

    _, cleaned_datasets = prepare_data(
        str(DATA_PATH)
    )

    print(
        f"Cleaned datasets prepared: "
        f"{len(cleaned_datasets)}"
    )

    engine = create_database_engine()

    try:
        with engine.connect() as connection:
            active_database = connection.execute(
                text("SELECT DATABASE()")
            ).scalar_one()

        if active_database != DATABASE_NAME:
            raise RuntimeError(
                f"Unexpected database: {active_database}"
            )

        print(
            f"Connected database: "
            f"{active_database}"
        )

        database_columns = validate_preload_state(
            cleaned_datasets,
            engine,
        )

        print(
            "Pre-load checks passed. "
            "Starting database load.\n"
        )

        for table_name in LOAD_ORDER:
            load_table(
                engine=engine,
                table_name=table_name,
                dataframe=cleaned_datasets[table_name],
                database_columns=database_columns[
                    table_name
                ],
            )

        print(
            "\nAll datasets loaded successfully."
        )

    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
