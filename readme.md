# QGIS Land Value Visualisation
## About the project
I utilised open data from the NSW government to show how land value per suburb had changed year-over-year (YoY). 

![gif-display](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/QGIS-yoy-change-land-value.gif)
> a blue suburb indicates that the land-value *increased* since the prior year, red indicates a *decrease* and white indicates that there was little or no change.

The geospatial GIF was created in QGIS, and the data was sourced from the NSW Land Valuer General

### Data Pipeline
![data-pipeline](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/final-data-pipeline.png)
Below are some scripts that were used as part of the pipeline.
```bash
for filepath in $(ls ~/land-value-data/*.zip)
do
	echo "Processing ${filepath}"
	if unzip $filepath -d ~/land-value-data/ ; then
		echo "${filepath} unzip success!"
		if gsutil -m cp ~/land-value-data/*.csv gs://super-bucket-man/land-value-data ; then
			echo "CSVs copied successfully! Deleting files."
            rm -f ~/land-value-data/*.csv
			rm -f $filepath
		else
			echo "CSVs copy failed.
		fi
	else
		echo "unzip failed. try again for file: ${filepath}"
	fi
	
	echo "remaining files:"
	ls ~/land-value-data/*.zip
done
```
The data given by the NSW land valuer general was multiple .ZIP files each containing multiple .CSVs. The script extracts and deletes each .ZIP file sequentially in order to stay under the cloud shell's 5GB storage limit.

After loading the csv files into BigQuery, the data gets cleaned and reduced down the relevant columns.
```sql
CREATE OR REPLACE TABLE `showcase-presentation.fullscale_dataset.suburb_aggregated_data` AS (
    SELECT
        ld.SUBURB_NAME, 
        lv.DATE_MONTH, 
        AVG(lv.LAND_VALUE) as avg_land_value,
        COUNT(ld.PROPERTY_ID) as property_count
    FROM 
        `showcase-presentation.fullscale_dataset.land_data_raw` AS ld
    INNER JOIN
        `showcase-presentation.fullscale_dataset.land_values` AS lv
        ON lv.PROPERTY_ID = ld.PROPERTY_ID
    GROUP BY
        ld.SUBURB_NAME, lv.DATE_MONTH
    ORDER BY 
        avg_land_value DESC, 
        lv.DATE_MONTH ASC, 
        ld.SUBURB_NAME DESC
);
```
> the results of this query get manually exported, and can be seen in [this file](https://github.com/omgardner/qgis-land-value-code/blob/master/data/results-suburb-aggregated-data.csv)

## Interesting Experiments done during the process to better understand the data
### networkx diagrams depicting how a postcode relates to suburb names
The code used can be found in [this jupyter notebook](https://github.com/omgardner/qgis-land-value-code/blob/master/notebooks/networkx-suburb-postcode-relationship.ipynb)
![networkx-suburb-postcode-nolabels](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/suburb-postcode-nolabels-network.png)
> green = suburb name, red = postcode

What was intriguing was that you couldn't use either of them as a unique identifier. They had a many to many relationship. Looking back on the project this was probably a flaw in the source data, because while a postcode can belong to many suburbs, a suburb name should be unique.

![networkx-suburb-postcode](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/suburb-postcode-network.png)
> the same network graph but with text per node

### BI Dashboard Test
At the time I was interested in Qlik as a BI tool, so I took the chance to throw some data into a dashboard.
![qlik-poc-v2](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/qlik-dash.png)
> QlikSense Dashboard proof of concept

It was a good way to learn more about BI tools at the time. 

### OSM Street data
The initial plan was to visualise land value change year-over-year per street. Instead of coloring suburbs it would have colored each street. However aggregating by street proved to be infeasable. 
But I did manage to import the OpenStreetMap data into QGIS, and explored how different kinds of roads and pathways were represented.
![osm](https://raw.githubusercontent.com/omgardner/qgis-land-value-code/master/images/image42-1.png)

## PROs and CONs of BigQuery
I explored the PROs and CONs of BigQuery.
### PROs
- no keys
    - my data had duplicate property IDs, so I it allowed me to not worry
- RECORD datatypes: ARRAYs and STRUCTs
    - interesting way to denormalise data whereas regular SQL would have been incapable
- easy to setup databases
    - schema gets inferred. In my case this was desirable
- first TB of queries is free
- data is stored internally by column, so queries will only process the columns that are necessary for the query versus the whole table
### CONs
- append only
    - as such it is bad for data cleaning
- couldn't automatically delete a temporary table / view
- can't import from a zip file containing .csv files
    - this is why I needed to unzip in the Cloud Shell
