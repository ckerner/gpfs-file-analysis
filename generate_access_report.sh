#!/bin/bash

for FS in `mount -t gpfs | awk '{print($1)}' | sort`
    do echo "Processing: ${FS}"
    ./file_analysis.pl -ac /${FS} | \
        grep -vE "^Processing" | while read DATAIN
        do printf "%s,%s\n" ${FS} "${DATAIN}"
    done
done | tee report_by_access_date.csv

