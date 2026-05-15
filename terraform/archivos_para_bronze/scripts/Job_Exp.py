import sys
import json
import logging
from datetime import datetime

from pyspark.context import SparkContext
from pyspark.sql.functions import current_timestamp

from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions

import great_expectations as gx

# -----------------------------------
# Argumentos del Job (vienen de default_arguments en Terraform)
# -----------------------------------
args = getResolvedOptions(
    sys.argv,
    ["input_path", "output_path"]
)
INPUT_PATH = args["input_path"]
OUTPUT_PATH = args["output_path"]

# -----------------------------------
# Inicializar Glue / Spark
# -----------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# -----------------------------------
# Configurar logger (para CloudWatch)
# -----------------------------------
logger = logging.getLogger("gx_logger")
logger.setLevel(logging.INFO)
logger.handlers = []

handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter("%(message)s")
handler.setFormatter(formatter)

logger.addHandler(handler)
logger.propagate = False

logger.info("GX LOGGER INICIADO")
print(f"INPUT_PATH  = {INPUT_PATH}")
print(f"OUTPUT_PATH = {OUTPUT_PATH}")

# -----------------------------------
# Leer datos (S3)
# -----------------------------------
df = spark.read.option("header", True).csv(INPUT_PATH)

# -----------------------------------
# Inicializar GX
# -----------------------------------
context = gx.get_context()

data_source = context.sources.add_or_update_spark(name="spark_source")
data_asset = data_source.add_dataframe_asset(name="hurto_data")

batch_request = data_asset.build_batch_request(dataframe=df)

# -----------------------------------
# Expectation Suite
# -----------------------------------
suite = context.add_or_update_expectation_suite("suite_hurtos")

validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite=suite,
)

# -----------------------------------
# VALIDACIONES
# -----------------------------------
validator.expect_table_columns_to_match_ordered_list(df.columns)
validator.expect_table_row_count_to_be_between(min_value=1)

validator.expect_column_values_to_not_be_null("fecha_hecho", mostly=0.99)
validator.expect_column_values_to_not_be_null("edad", mostly=0.95)

validator.expect_column_values_to_be_between("edad", min_value=0, max_value=100, mostly=0.97)
validator.expect_column_values_to_be_in_set(
    "medio_transporte",
    ["Taxi", "Metro", "Autobus", "Bicicleta"],
    mostly=0.90,
)

validator.expect_column_value_lengths_to_be_between(
    column="arma_medio",
    min_value=2,
)

validator.expect_column_values_to_be_in_set(
    "sexo",
    ["Hombre", "Mujer"],
    mostly=0.70,
)

# Latitud Medellín
validator.expect_column_values_to_be_between(
    "latitud",
    min_value=6.15,
    max_value=6.35,
    mostly=0.80,
)

# Longitud Medellín
validator.expect_column_values_to_be_between(
    "longitud",
    min_value=-75.65,
    max_value=-75.50,
    mostly=0.80,
)

# -----------------------------------
# Ejecutar validación
# -----------------------------------
results = validator.validate()
results_json = results.to_json_dict()

# -----------------------------------
# Logging estructurado (CloudWatch)
# -----------------------------------
log_payload = {
    "event": "great_expectations_validation",
    "timestamp": datetime.utcnow().isoformat(),
    "success": results_json.get("success"),
    "statistics": results_json.get("statistics"),
    "run_id": results_json.get("meta", {}).get("run_id"),
}

logger.info(json.dumps(log_payload))
print(json.dumps(log_payload))

# -----------------------------------
# Log de fallos
# -----------------------------------
failed_expectations = [
    {
        "expectation": r.get("expectation_config", {}).get("expectation_type"),
        "column": r.get("expectation_config", {}).get("kwargs", {}).get("column"),
        "success": r.get("success"),
    }
    for r in results_json.get("results", [])
    if not r.get("success")
]

if failed_expectations:
    fail_payload = {
        "event": "gx_failed_expectations",
        "count": len(failed_expectations),
        "details": failed_expectations[:10],
    }
    logger.warning(json.dumps(fail_payload))
    print(json.dumps(fail_payload))

# -----------------------------------
# Guardar resultados en S3 (JSON)
# -----------------------------------
results_str = json.dumps(results_json)

results_df = spark.createDataFrame(
    [(results_str,)],
    ["validation_results"],
).withColumn("timestamp", current_timestamp())

results_df.coalesce(1).write.mode("overwrite").json(OUTPUT_PATH)

# -----------------------------------
# Control de fallo
# -----------------------------------
if not results["success"]:
    raise Exception("Data Quality FAILED")
