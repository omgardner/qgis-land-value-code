# About
> Included here are some code snippets from my project.

![gif-display](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/QGIS-yoy-change-land-value.gif)
> YoY land value percentage change across NSW, Australia. Some suburbs change in tandem, some are outliers. 

![networkx-suburb-postcode-nolabels](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/suburb-postcode-nolabels-network.png)
> networkx diagram showing a subset of the unique pairs of suburb_name, postcode. It demonstrates that there's actually a m:n relationship going on.

![networkx-suburb-postcode](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/suburb-postcode-network.png)
> Same as above, but with lables.

![qlik-poc-v2](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/qlik-dash.png)
> QlikSense Dashboard proof of concept

```sql
CREATE OR REPLACE TABLE `showcase-presentation.fullscale_dataset.street_name_agg_table` AS (
    SELECT
    -- inefficient way of retrieving the higher level granularities for the STREET_NAME
        MIN(ld.DISTRICT_NAME) AS DISTRICT_NAME, 
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
) 
```
> BigQuery Query used to make the above QlikSense PoC

![big-data](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/image-20210609101859073.png)
> Before I realised that the source was duplicating data, the 12 .zip files uncompressed + BQ denormalisation created this crazy 8.14GB table.

### PROs and CONs of BQ
#### PROs
- no keys
    - my data had duplicate property IDs.
- RECORD datatypes: ARRAYs and STRUCTs
    - interesting way to denormalise data whereas regular SQL would have been incapable
- easy to setup databases
    - schema gets inferred. In my case this was desirable
- first TB of queries is free
- data is stored internally by column, so queries will only process the columns that are necessary for the query versus the whole table
#### CONs
- append only
    - as such it is suboptimal for data cleaning
- couldn't automatically delete a tmp table / view
- can't import from a zip file containing .csv files
    - this is why I needed to unzip in the Cloud Console
