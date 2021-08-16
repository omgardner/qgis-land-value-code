-- create temp table to convert separate date and land_value columns into a single record column
-- super-bucket-man/land-value-data/*.csv
CREATE OR REPLACE TABLE `showcase-presentation.fullscale_dataset.land_value_as_records_temp` AS (
    SELECT 
        PROPERTY_ID,
        [
            STRUCT(BASE_DATE_1 AS DATE_MONTH,LAND_VALUE_1 AS LAND_VALUE),
            STRUCT(BASE_DATE_2 AS DATE_MONTH,LAND_VALUE_2 AS LAND_VALUE),
            STRUCT(BASE_DATE_3 AS DATE_MONTH,LAND_VALUE_3 AS LAND_VALUE),
            STRUCT(BASE_DATE_4 AS DATE_MONTH,LAND_VALUE_4 AS LAND_VALUE),
            STRUCT(BASE_DATE_5 AS DATE_MONTH,LAND_VALUE_5 AS LAND_VALUE)
        ] AS date_value_pairs

    FROM `showcase-presentation.fullscale_dataset.land_data_raw`
);

-- using the land_value_as_records_temp table, creates a table with person id, date and land_value in 3 fields.
CREATE OR REPLACE TABLE `showcase-presentation.fullscale_dataset.land_values` AS ( 
    SELECT
        PROPERTY_ID, 
        DATE_MONTH, 
        LAND_VALUE
    FROM 
        `showcase-presentation.fullscale_dataset.land_value_as_records_temp`,
    UNNEST(date_value_pairs)
    WHERE 
        -- business logic: if there is no value, then there is no reason to have the row at all
        LAND_VALUE IS NOT NULL 
);

-- drop the temporary table as it is no longer needed
DROP TABLE IF EXISTS
	`showcase-presentation.fullscale_dataset.land_value_as_records_temp`;
	
-- sometimes property details change over time. They can change zone, suburb, district, etc.
CREATE OR REPLACE TABLE `showcase-presentation.fullscale_dataset.land_details_plus_problem_rows` AS (
    SELECT DISTINCT 
        PROPERTY_ID, 
        DISTRICT_CODE,
        DISTRICT_NAME,
        PROPERTY_NAME,
        HOUSE_NUMBER,
        STREET_NAME,
        SUBURB_NAME,
        POSTCODE,
        ZONE_CODE,
        -- standardises the units for the AREA column, therefore the AREA_TYPE column is no longer necessary
        CASE WHEN AREA_TYPE = "H" THEN AREA * 10000 ELSE AREA END AS AREA_M2
    FROM 
        `showcase-presentation.fullscale_dataset.land_data_raw`
);
	
-- super-bucket-man/land-value-data/*20210601.csv
-- land_data_latest_raw

-- since this is the data from only 1 of the .zip files (versus the 12 for the land_data_raw table), there should be no duplicate PROPERTY_IDs in this table 
CREATE OR REPLACE TABLE `showcase-presentation.fullscale_dataset.land_details_latest` AS (
    SELECT
        PROPERTY_ID, 
        DISTRICT_CODE,
        DISTRICT_NAME,
        PROPERTY_NAME,
        HOUSE_NUMBER,
        STREET_NAME,
        SUBURB_NAME,
        POSTCODE,
        ZONE_CODE,
        -- standardises the units for the AREA column, therefore the AREA_TYPE column is no longer necessary
        CASE WHEN AREA_TYPE = "H" THEN AREA * 10000 ELSE AREA END AS AREA_M2
    FROM 
        `showcase-presentation.fullscale_dataset.land_data_latest_raw`
);

-- nice to have, but was part of an analysis more focused on grouping values by the street name
CREATE OR REPLACE TABLE `showcase-presentation.fullscale_dataset.street_name_agg_table` AS (
    SELECT
    -- inefficient way of retrieving the higher level granularities for the STREET_NAME
        MIN(ld.DISTRICT_NAME) AS DISTRICT_NAME, 
        MIN(ld.DISTRICT_CODE) AS DISTRICT_CODE, 
        MIN(ld.SUBURB_NAME) AS SUBURB_NAME, 
        MIN(ld.POSTCODE) AS POSTCODE, 
        ld.STREET_NAME, 
        -- gets first element from an array of structs, 
        --   then gets the string value corresponding to the "value" key
        APPROX_TOP_COUNT(ld.ZONE_CODE, 1)[OFFSET(0)].value AS most_frequent_zone_code,
        AVG(lv.LAND_VALUE) AS avg_land_value,
        AVG(ld.AREA_M2) AS avg_area_m2
    FROM 
        `showcase-presentation.fullscale_dataset.land_details_latest` AS ld
    INNER JOIN 
        `showcase-presentation.fullscale_dataset.land_values` AS lv ON lv.PROPERTY_ID = ld.PROPERTY_ID
    WHERE 
        ld.STREET_NAME IS NOT NULL
    GROUP BY 
        ld.STREET_NAME
    ORDER BY
        avg_land_value DESC
);

-- remove the original raw data table
DROP TABLE IF EXISTS
	`showcase-presentation.fullscale_dataset.land_data_raw`;
	
-- remove the latest raw data table
DROP TABLE IF EXISTS
	`showcase-presentation.fullscale_dataset.land_data_latest_raw`;