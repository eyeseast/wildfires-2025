import maplibregl from "maplibre-gl";
import * as pmtiles from "pmtiles";
import layers from "protomaps-themes-base";

const protocol = new pmtiles.Protocol();

maplibregl.addProtocol("pmtiles", protocol.tile);

const style = {
  version: 8,
  glyphs: "./fonts/{fontstack}/{range}.pbf",
  sources: {
    protomaps: {
      type: "vector",
      url: "pmtiles://" + "base.pmtiles",
      attribution:
        '<a href="https://protomaps.com">Protomaps</a> © <a href="https://openstreetmap.org">OpenStreetMap</a>',
    },

    // load our fire data
    fires: {
      type: "geojson",
      data: "fires.geojson",
    },
  },

  // this builds a set of layers matching the OpenMapTiles schema, using "protomaps" as a source ID
  layers: layers("protomaps", "grayscale"),
};

const map = new maplibregl.Map({
  container: "map",
  style,
  maxBounds: [-121.916742, 32.141279, -113.611078, 35.642196],
  hash: true,
  center: [-117.938232, 34.170908],
  maxZoom: 12,
});

map.once("load", (e) => {
  const firstSymbolLayer = map
    .getStyle()
    .layers.find((layer) => layer.type === "symbol");

  // add our fire layer here
  map.addLayer(
    {
      id: "fires-fill",
      type: "fill",
      source: "fires",
      paint: {
        "fill-color": "#fd8d3c",
        "fill-opacity": 0.5,
      },
    },
    firstSymbolLayer.id
  );

  map.addLayer({
    id: "fires-outline",
    type: "line",
    source: "fires",
    paint: {
      "line-color": "#fed976",
      "line-opacity": 0.5,
      "line-width": ["interpolate", ["linear", 0.5], ["zoom"], 6, 0, 16, 0.75],
    },
  });

  map.addControl(new maplibregl.NavigationControl());
  map.addControl(new maplibregl.FullscreenControl());
});

window.map = map;
