DB = fires.db

SU = uv run sqlite-utils

BBOX = -121.916742,32.141279,-113.611078,35.642196

FILES_GEOJSON = https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/WFIGS_Interagency_Perimeters_YearToDate/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson

# https://maps.protomaps.com/builds/
TODAY = $(shell date -v -1d +%Y%m%d) # actually yesterday
PMTILES_BUILD = https://build.protomaps.com/$(TODAY).pmtiles

install:
	uv sync
	npm ci

build:
	docker build . -t self-hosted-maps:latest

update: fires tiles

container:
	docker run --rm -it self-hosted-maps:latest

tiles: public/base.pmtiles

fires: $(DB) data/fires.geojson
	uv run geojson-to-sqlite $(DB) $@ data/fires.geojson --spatialite --pk OBJECTID

fonts:
	wget https://github.com/protomaps/basemaps-assets/archive/refs/heads/main.zip
	unzip main.zip
	mv basemaps-assets-main/fonts public/fonts
	rm -r basemaps-assets-main main.zip

run:
	# https://docs.datasette.io/en/stable/settings.html#configuration-directory-mode
	npm run dev -- --open & uv run datasette serve . --load-extension spatialite -h 0.0.0.0

ds:
	uv run datasette serve . --load-extension spatialite -h 0.0.0.0

clean:
	rm -rf public/fires.* data/fires.*

data/fires.geojson:
	curl "$(FILES_GEOJSON)" | jq > $@

$(DB):
	$(SU) create-database $@ --enable-wal --init-spatialite

public/base.pmtiles:
	pmtiles extract $(PMTILES_BUILD) $@ --bbox="$(BBOX)" --maxzoom 12

public/fires.pmtiles: data/fires.geojson
	tippecanoe -zg -o $@ --layer fires $^

public/fires.mbtiles: data/fires.geojson
	tippecanoe -f -zg -o $@ --layer fires $^

public/fires.geojson: data/fires.geojson
	fio cat $^ --bbox "$(BBOX)" | fio collect > $@

public/fires.fgb: data/fires.geojson
	ogr2ogr -f FlatGeoBuf $@ $^
