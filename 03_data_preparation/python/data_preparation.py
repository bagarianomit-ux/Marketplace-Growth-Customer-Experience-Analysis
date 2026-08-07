from pathlib import Path
import pandas as pd


FILE_MAP = {
    "customers": "olist_customers_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "payments": "olist_order_payments_dataset.csv",
    "reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}


PRODUCT_COLUMN_RENAME_MAP = {
    "product_name_lenght": "product_name_length",
    "product_description_lenght": "product_description_length",
}


DATETIME_COLUMNS = {
    "orders": [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "order_items": [
        "shipping_limit_date",
    ],
    "reviews": [
        "review_creation_date",
        "review_answer_timestamp",
    ],
}


ZIP_COLUMNS = {
    "customers": "customer_zip_code_prefix",
    "sellers": "seller_zip_code_prefix",
    "geolocation": "geolocation_zip_code_prefix",
}


PRODUCT_INTEGER_COLUMNS = [
    "product_name_length",
    "product_description_length",
    "product_photos_qty",
    "product_weight_g",
    "product_length_cm",
    "product_height_cm",
    "product_width_cm",
]


TEXT_COLUMNS = {
    "customers": [
        "customer_city",
        "customer_state",
    ],
    "sellers": [
        "seller_city",
        "seller_state",
    ],
    "geolocation": [
        "geolocation_city",
        "geolocation_state",
    ],
    "orders": [
        "order_status",
    ],
    "payments": [
        "payment_type",
    ],
    "products": [
        "product_category_name",
    ],
    "reviews": [
        "review_comment_title",
        "review_comment_message",
    ],
    "category_translation": [
        "product_category_name",
        "product_category_name_english",
    ],
}


TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"


def load_raw_data(data_path):
    """Load the nine raw Olist source datasets."""

    data_path = Path(data_path)

    missing_files = [
        filename
        for filename in FILE_MAP.values()
        if not (data_path / filename).exists()
    ]

    if missing_files:
        raise FileNotFoundError(
            "The following source files were not found:\n"
            + "\n".join(missing_files)
        )

    return {
        table_name: pd.read_csv(
            data_path / filename,
            low_memory=False,
        )
        for table_name, filename in FILE_MAP.items()
    }


def standardise_zip_prefix(series):
    """Convert ZIP prefixes to five-character strings."""

    numeric_values = pd.to_numeric(
        series,
        errors="raise",
    )

    non_null_values = numeric_values.dropna()

    if not (non_null_values % 1 == 0).all():
        raise ValueError(
            "ZIP-code prefixes contain non-integer values."
        )

    if not non_null_values.between(0, 99999).all():
        raise ValueError(
            "ZIP-code prefixes contain values outside "
            "the expected five-digit range."
        )

    return (
        numeric_values
        .astype("Int64")
        .astype("string")
        .str.zfill(5)
    )


def clean_data(datasets_raw):
    """Apply the cleaning transformations approved in C2."""

    expected_tables = set(FILE_MAP)
    available_tables = set(datasets_raw)

    missing_tables = expected_tables - available_tables
    unexpected_tables = available_tables - expected_tables

    if missing_tables:
        raise KeyError(
            "Missing source datasets: "
            + ", ".join(sorted(missing_tables))
        )

    if unexpected_tables:
        raise KeyError(
            "Unexpected source datasets: "
            + ", ".join(sorted(unexpected_tables))
        )

    datasets_clean = {
        table_name: dataframe.copy()
        for table_name, dataframe in datasets_raw.items()
    }

    missing_product_columns = [
        column
        for column in PRODUCT_COLUMN_RENAME_MAP
        if column not in datasets_clean["products"].columns
    ]

    if missing_product_columns:
        raise KeyError(
            "Expected product columns were not found: "
            + ", ".join(missing_product_columns)
        )

    datasets_clean["products"] = (
        datasets_clean["products"].rename(
            columns=PRODUCT_COLUMN_RENAME_MAP
        )
    )

    for table_name, columns in DATETIME_COLUMNS.items():
        for column in columns:
            datasets_clean[table_name][column] = pd.to_datetime(
                datasets_clean[table_name][column],
                format=TIMESTAMP_FORMAT,
                errors="raise",
            )

    for table_name, dataframe in datasets_clean.items():
        object_columns = dataframe.select_dtypes(
            include="object"
        ).columns

        for column in object_columns:
            datasets_clean[table_name][column] = (
                datasets_clean[table_name][column]
                .astype("string")
            )

    for table_name, column in ZIP_COLUMNS.items():
        datasets_clean[table_name][column] = (
            standardise_zip_prefix(
                datasets_clean[table_name][column]
            )
        )

    for column in PRODUCT_INTEGER_COLUMNS:
        numeric_values = pd.to_numeric(
            datasets_clean["products"][column],
            errors="raise",
        )

        non_null_values = numeric_values.dropna()

        if not non_null_values.mod(1).eq(0).all():
            raise ValueError(
                f"{column} contains non-integer values and "
                "cannot be converted to Int64 without rounding."
            )

        datasets_clean["products"][column] = (
            numeric_values.astype("Int64")
        )

    for table_name, columns in TEXT_COLUMNS.items():
        for column in columns:
            datasets_clean[table_name][column] = (
                datasets_clean[table_name][column]
                .str.strip()
                .replace("", pd.NA)
            )

    datasets_clean["geolocation"] = (
        datasets_clean["geolocation"]
        .drop_duplicates()
        .reset_index(drop=True)
    )

    return datasets_clean


def prepare_data(data_path):
    """Load raw data and return raw and cleaned datasets."""

    datasets_raw = load_raw_data(data_path)
    datasets_clean = clean_data(datasets_raw)

    return datasets_raw, datasets_clean
