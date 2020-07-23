#!/bin/bash

infolder="CFSv2/norientation/"
outfolder="CFSv2/shapefiles/"

dayArray=(1 2 3 4 5 6)
dateArray=("30-09" "01/10-15/10" "16/10-31/10" "01/11-15/11" "16/11-30/11" "01/12")

for i in $(ls $infolder*".tif"); do
    FILENAME=$(echo $i|sed 's/.*\///')
    FILENAME=$(echo $FILENAME|sed -r 's/.tif//g')

    DATE=${FILENAME:15:23}

    r.in.gdal --overwrite -o input="utils/mae"$DATE".tif" output="MAE"

    r.in.gdal --overwrite -o input=$i output=$FILENAME

    g.region raster=$FILENAME

    r.reclass --overwrite input=$FILENAME output="reclass" rules="utils/reclassify.txt"

    r.to.vect --overwrite -s input="reclass" output="shape" type="area" column="onset"

    v.db.addcolumn map="shape" columns="date VARCHAR(12)"

    for ((j=0; j<${#dayArray[@]}; j++)) do
        v.db.update map=shape column="date" value=${dateArray[$j]} where="onset= ${dayArray[$j]}"
    done

    v.generalize --overwrite input="shape" type="area" output="lang" method="lang" threshold=1

    v.generalize --overwrite input="lang" output="chaiken" method="chaiken" threshold=1

    v.rast.stats -c map="chaiken" raster="MAE" column_prefix="mae" method="average,median"

    db.login --overwrite driver=pg database=obahia user=geonode password=uppQAOFa host=obahia.dea.ufv.br port=5432
    v.out.postgis --overwrite input="chaiken" type="area" output=PG:dbname=obahia output_layer=vector."onset_forecast" options="SRID=4326"

    v.db.renamecolumn map="chaiken" column="mae_average,mae_avr"
    v.out.ogr --overwrite -s -e input="chaiken" type="area" output=$outfolder$FILENAME".shp" format="ESRI_Shapefile"

#   g.remove -i -f -b type=raster,vector pattern=*
done

#rm -rf $infolder*.tif
#rm -rf CFSv2/soma/*.nc
#rm -rf CFSv2/onsetforecast/*.nc
#rm -rf CFSv2/geotiff/*.tif

