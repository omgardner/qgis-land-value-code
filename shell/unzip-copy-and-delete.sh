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