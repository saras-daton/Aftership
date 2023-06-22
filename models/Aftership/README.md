# Aftership Data Unification

This dbt package is for the Shopify data unification Ingested by [Daton](https://sarasanalytics.com/daton/). [Daton](https://sarasanalytics.com/daton/) is the Unified Data Platform for Global Commerce with 100+ pre-built connectors and data sets designed for accelerating the eCommerce data and analytics journey by [Saras Analytics](https://sarasanalytics.com).

### Supported Datawarehouses:
- BigQuery
- Snowflake

#### Typical challanges with raw data are:
- Array/Nested Array columns which makes queries for Data Analytics complex
- Data duplication due to look back period while fetching report data from Shopify
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

Models will be create unified tables under the schema (<target_schema>_stg_shopify). In case, you would like the models to be written to the target schema or a different custom schema, please add the following in the dbt_project.yml file.

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
    "Shopify.Raw.Brand_UK_Shopify_orders":-7,
    "Shopify.Raw.Brand_UK_Shopify_products":-7
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

This package contains models from the Shopify API which includes reports on {{sales, margin, inventory, product}}. The primary outputs of this package are described below.

| **Category**                 | **Model**  | **Description** |
| ------------------------- | ---------------| ----------------------- |
|Customer | [ShopifyCustomers](models/Shopify/ShopifyCustomers.sql)  | A detailed report which gives infomration about Customers |
|Addresses | [ShopifyCustomersAddresses](models/Shopify/ShopifyCustomersAddresses.sql)  | A detailed report which gives infomration about the addresses of each customer |
|Inventory | [ShopifyInventory](models/Shopify/ShopifyInventory.sql)  | A detailed report which gives infomration about inventory levels |
|Orders | [ShopifyOrdersAddresses](models/Shopify/ShopifyOrdersAddresses.sql)  | A list of billing and shipping addresses |
|Orders | [ShopifyOrdersCustomer](models/Shopify/ShopifyOrdersCustomer.sql)| A report of orders at customer level |
|Orders | [ShopifyOrdersLineItemsDiscounts](models/Shopify/ShopifyOrdersLineItemsDiscounts.sql)| A report of orders with discount allocations |
|Orders | [ShopifyOrdersFulfillmentOrders](models/Shopify/ShopifyOrdersFulfillmentOrders.sql)| A report of orders with fulfillment details, destinations and assigned locations. |
|Orders | [ShopifyOrdersFulfillments](models/Shopify/ShopifyOrdersFulfillments.sql)| A report of orders with fulfillment details, destinations and assigned locations at product level.|
|Orders | [ShopifyOrdersLineItemsTaxLines](models/Shopify/ShopifyOrdersLineItemsTaxLines.sql)| A list of orders with  product level taxes. |
|Orders | [ShopifyOrdersLineItems](models/Shopify/ShopifyOrdersLineItems.sql)| A list of orders at product level |
|Orders | [ShopifyOrdersRefundLines](models/Shopify/ShopifyOrdersRefundLines.sql)| A list of refunded orders which includes refund & order level revenue. |
|Orders | [ShopifyOrdersRefundsLineItems](models/Shopify/ShopifyOrdersRefundsLineItems.sql)| A list of refunded orders which includes refund & product level revenue. |
|Orders | [ShopifyOrdersRefundsTaxLines](models/Shopify/ShopifyOrdersRefundsTaxLines.sql)| A list of taxes associated with the refunded item. |
|Orders | [ShopifyOrdersShippingLines](models/Shopify/ShopifyOrdersShippingLines.sql)| A list of orders with shipping details |
|Orders | [ShopifyOrdersTransactions](models/Shopify/ShopifyOrdersTransactions.sql)| A list of order transactions |
|Orders | [ShopifyOrders](models/Shopify/ShopifyOrders.sql)| A list of orders |
|Product | [ShopifyProduct](models/Shopify/ShopifyProduct.sql)| A list of product summary, manufacturer & dimensions |
|Refunds | [ShopifyRefundsTransactions](models/Shopify/ShopifyRefundsTransactions.sql)| A list of refund transactions |
|Transactions | [ShopifyTransactions](models/Shopify/ShopifyTransactions.sql)| A report of transactions with transactions fees, sources and status. |
|Countries | [ShopifyCountries](models/Shopify/ShopifyCountries.sql)| A list of countries. |
|Events | [ShopifyEvents](models/Shopify/ShopifyEvents.sql)| A list of events. |
|Shops | [ShopifyShop](models/Shopify/ShopifyShop.sql)| Shop is a shopping destination and delivery tracking app that can be used  to track packages, discover new stores and products, make purchases using Shop Pay , and engage with your brand. |
|Checkouts | [ShopifyCheckouts](models/Shopify/ShopifyCheckouts.sql)| Checkout are used to enter their shipping information and payment details before placing the order. |
|Transactions | [ShopifyTenderTransactions](models/Shopify/ShopifyTenderTransactions.sql)| Tender transaction created trigger starts a workflow when a monetary action such as a payment or refund takes place. |
|Policies | [ShopifyPolicies](models/Shopify/ShopifyPolicies.sql)| List of policies for your Shopify store like Refund policy, Privacy policy, Terms of service, Shipping policy, Legal notice. |
|Collections | [ShopifySmartCollections](models/Shopify/ShopifySmartCollections.sql)| An automated collection uses selection conditions to automatically include matching products. |
|Collections | [ShopifyCollects](models/Shopify/ShopifyCollects.sql)| A list of collections. |
|Locations | [ShopifyLocations](models/Shopify/ShopifyLocations.sql)| Locations can be retail stores, warehouses, popups, dropshippers, or any other place where you manage or stock inventory. |
|Price Rules | [ShopifyPriceRules](models/Shopify/ShopifyPriceRules.sql)| A list of rules to set pricing. |
|Carrier Services | [ShopifyCarrierServices](models/Shopify/ShopifyCarrierServices.sql)| A list of carrier services. |
|Payouts | [ShopifyPayouts](models/Shopify/ShopifyPayouts.sql)| lists all of your payouts and their current status. |




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
