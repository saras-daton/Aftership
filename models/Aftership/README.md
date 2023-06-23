# Aftership Data Unification

This dbt package is for the Aftership data unification Ingested by [Daton](https://sarasanalytics.com/daton/). [Daton](https://sarasanalytics.com/daton/) is the Unified Data Platform for Global Commerce with 100+ pre-built connectors and data sets designed for accelerating the eCommerce data and analytics journey by [Saras Analytics](https://sarasanalytics.com).

### Supported Datawarehouses:
- BigQuery
- Snowflake

#### Typical challanges with raw data are:
- Array/Nested Array columns which makes queries for Data Analytics complex
- Data duplication due to look back period while fetching report data from Aftership
- Seperate tables at marketplaces/Store, brand, account level for same kind of report/data feeds

By doing Data Unification the above challenges can be overcomed and simplifies Data Analytics. 
As part of Data Unification, the following funtions are performed:
- Consolidation - Different marketplaces/Store/account & different brands would have similar raw Daton Ingested tables, which are consolidated into one table with column distinguishers brand & store
- Deduplication - Based on primary keys, the data is De-duplicated and the latest records are only loaded into the consolidated stage tables
- Incremental Load - Models are designed to include incremental load which when scheduled would update the tables regularly
- Standardization -
	- Currency Conversion (Optional) - Raw Tables data created at Marketplace/Store/Account level may have data in local currency of the corresponding marketplace/store/account. Values that are in local currency are standardized by converting to desired currency using Daton Exchange Rates data.
	  Prerequisite - Exchange Rates connector in Daton needs to be present - Refer [this](https://github.com/saras-daton/currency_exchange_rates)
	- Time Zone Conversion (Optional) - Raw Tables data created at Marketplace/Store/Account level may have data in local timezone of the corresponding marketplace/store/account. DateTime values that are in local timezone are standardized by converting to specified timezone using input offset hours.

#### Prerequisite 
Daton Integrations for  
- Aftership 
- Exchange Rates(Optional, if currency conversion is not required)

*Note:* 
*Please select 'Do Not Unnest' option while setting up Daton Integrataion*

# Configuration 

## Required Variables

This package assumes that you have an existing dbt project with a BigQuery/Snowflake profile connected & tested. Source data is located using the following variables which must be set in your `dbt_project.yml` file.
```yaml
vars:
    raw_database: "your_database"
    raw_schema: "your_schema"
```

## Setting Target Schema

Models will be create unified tables under the schema (<target_schema>_stg_Aftership). In case, you would like the models to be written to the target schema or a different custom schema, please add the following in the dbt_project.yml file.

```yaml
models:
  aftership:
    +schema: custom_schema_extension
```

## Optional Variables

Package offers different configurations which must be set in your `dbt_project.yml` file. These variables can be marked as True/False based on your requirements. Details about the variables are given below.

### Currency Conversion 

To enable currency conversion, which produces two columns - exchange_currency_rate & exchange_currency_code, please mark the currency_conversion_flag as True. By default, it is False.
Prerequisite - Daton Exchange Rates Integration

Example:
```yaml
vars:
    currency_conversion_flag: True
```

### Timezone Conversion

To enable timezone conversion, which converts the timezone columns from UTC timezone to local timezone, please mark the timezone_conversion_flag as True in the dbt_project.yml file, by default, it is False. Additionally, you need to provide offset hours between UTC and the timezone you want the data to convert into for each raw table for which you want timezone converison to be taken into account.

Example:
```yaml
vars:
timezone_conversion_flag: True
  raw_table_timezone_offset_hours: {
    "Aftership.Raw.AftershipTrackings":-2,
    "Aftership.Raw.AftershipTrackingsCouriers":-2
  }
```
Here, -7 represents the offset hours between UTC and PDT considering we are sitting in PDT timezone and want the data in this timezone

### Table Exclusions

If you need to exclude any of the models, declare the model names as variables and mark them as False. Refer the table below for model details. By default, all tables are created.

Example:
```yaml
vars:
AftershipCouriers: False
```

## Models

This package contains models from the Aftership API which includes reports on {{sales, margin, inventory, product}}. The primary outputs of this package are described below.

| **Category**                 | **Model**  | **Description** |
| ------------------------- | ---------------| ----------------------- |
|Customer | [AftershipCouriers](models/Aftership/AftershipCouriers.sql)  | A detailed report which gives infomration about Aftership Couriers |
|Addresses | [AftershipUserActivatedCouriers](models/Aftership/AftershipUserActivatedCouriers.sql)  | A detailed report which gives infomration about the active users couriers |
|Inventory | [AftershipTrackings](models/Aftership/AftershipTrackings.sql)  | A detailed report which gives infomration about shipment trackings |
|Orders | [AftershipTrackingsCheckpoints](models/Aftership/AftershipTrackingsCouriers.sql)  | A detailed report which gives infomration about shipment trackings for every checkpoints |




### For details about default configurations for Table Primary Key columns, Partition columns, Clustering columns, please refer the properties.yaml used for this package as below. 
	You can overwrite these default configurations by using your project specific properties yaml.
```yaml
version: 2
models:
  - name: AftershipCouriers
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['slug','name','phone','web_url']
      cluster_by: ['slug','name','phone','web_url'] 
    columns:
      - name: brand
        tests:
          - not_null
      - name: store
        tests:
          - not_null
      - name: slug
        tests:
          - not_null   
      - name: name
        tests:
          - not_null
      - name: web_url
        tests:
          - not_null
      - name: default_language
        tests:
          - not_null

  - name: AftershipUserActivatedCouriers
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['slug','name','phone','web_url']
      cluster_by: ['slug','name','phone','web_url'] 
    columns:
      - name: brand
        tests:
          - not_null
      - name: store
        tests:
          - not_null
      - name: slug
        tests:
          - not_null   
      - name: name
        tests:
          - not_null
      - name: web_url
        tests:
          - not_null
      - name: default_language
        tests:
          - not_null

  - name: AftershipTrackings
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['id']
      partition_by: { 'field': 'created_at', 'data_type': 'timestamp', 'granularity': 'day'  }
      cluster_by: ['id'] 
    columns:
      - name: id  
        tests:   
          - not_null   
      - name: brand
        tests:
          - not_null
      - name: store
        tests:
          - not_null
      - name: active
        tests:
          - not_null 
          - accepted_values:
              values: ["True","False"] 
      - name: tracking_number
        tests:
          - not_null
      - name: order_id
        tests:
          - not_null
      - name: order_number
        tests:
          - not_null
      - name: tag
        tests:
          - not_null 
          - accepted_values:
              values: ["Exception","Delivered","InfoReceived","Expired","OutForDelivery","InTransit","AttemptFail","AvailableForPickup","Pending"]  
      - name: created_at
        tests:
          - not_null
      - name: updated_at
        tests:
          - not_null
          - dbt_expectations.expect_row_values_to_have_recent_data:
              datepart: day
              interval: 1
      - name: last_updated_at
        tests:
          - not_null 
    tests:    
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - id

  - name: AftershipTrackingsCheckpoints
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['id', 'checkpoints_created_at']
      partition_by: { 'field': 'created_at', 'data_type': 'timestamp', 'granularity': 'day'  }
      cluster_by: ['id','checkpoints_created_at'] 
    columns:
      - name: id  
        tests:   
          - not_null   
      - name: brand
        tests:
          - not_null
      - name: store
        tests:
          - not_null
      - name: active
        tests:
          - not_null 
          - accepted_values:
              values: ["True","False"]
      - name: tracking_number
        tests:
          - not_null
          - relationships:
              to: ref('AftershipTrackings')
              field: tracking_number
      - name: order_id
        tests:
          - not_null
      - name: order_number
        tests:
          - not_null
      - name: tag
        tests:
          - not_null
          - accepted_values:
              values: ["Exception","Delivered","InfoReceived","Expired","OutForDelivery","InTransit","AttemptFail","AvailableForPickup","Pending"]
      - name: created_at
        tests:
          - not_null
      - name: updated_at
        tests:
          - not_null
          - dbt_expectations.expect_row_values_to_have_recent_data:
              datepart: day
              interval: 1
      - name: last_updated_at
        tests:
          - not_null
      - name: checkpoints_created_at
        tests:
          - not_null
    tests:   
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - id
            - checkpoints_created_at

```



## Resources:
- Have questions, feedback, or need [help](https://calendly.com/srinivas-janipalli/30min)? Schedule a call with our data experts or email us at info@sarasanalytics.com.
- Learn more about Daton [here](https://sarasanalytics.com/daton/).
- Refer [this](https://youtu.be/6zDTbM6OUcs) to know more about how to create a dbt account & connect to {{Bigquery/Snowflake}}
