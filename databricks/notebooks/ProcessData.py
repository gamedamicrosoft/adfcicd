# Databricks notebook source

# Retrieve storage account key from parameters
storage_account_key = dbutils.widgets.get("storage_account_key")
spark.conf.set("fs.azure.account.key.gamedacicd19dec.blob.core.windows.net", storage_account_key)
# Load the CSV file from Azure Blob Storage
df = spark.read.csv("wasbs://container1@gamedacicd19dec.blob.core.windows.net/dir1/sample_adf_data.csv", header=True, inferSchema=True)

# Perform a simple transformation
df_filtered = df.filter(df.Age > 30)

# Write the transformed data back to Blob Storage
df_filtered.write.csv("wasbs://container1@gamedacicd19dec.blob.core.windows.net/output/", mode="overwrite", header=True)

#df_filtered.show()