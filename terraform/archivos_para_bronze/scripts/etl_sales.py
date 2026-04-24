import sys
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date


def transform(df):
    return (
        df.withColumn("order_id", col("order_id").cast("int"))
          .withColumn("customer_id", col("customer_id").cast("int"))
          .withColumn("amount", col("amount").cast("double"))
          .withColumn("date", to_date(col("date"), "yyyy-MM-dd"))
    )


def main():
    args = getResolvedOptions(sys.argv, ['input_path', 'output_path'])

    spark = SparkSession.builder.getOrCreate()

    df = spark.read.option("header", "true").csv(args['input_path'])

    df_transformed = transform(df)

    df_transformed.write \
        .mode("overwrite") \
        .partitionBy("date") \
        .parquet(args['output_path'])


if __name__ == "__main__":
    main()