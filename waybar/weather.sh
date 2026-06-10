#!/bin/bash

icon=$(omarchy-weather-icon 2>/dev/null)
[[ -z $icon ]] && icon=""

weather=$(curl -fsS --max-time 4 "https://wttr.in?format=%l|%t|%w" 2>/dev/null | tr -d '\n')
if [[ -n $weather ]]; then
    IFS='|' read -r place temperature wind <<< "$weather"
    place=${place%%,*}
    place=${place^}
    temperature=${temperature#+}
    weather_line="$place  ·  Temp $temperature  ·  Wind $wind"
else
    weather_line="Weather unavailable"
fi

metar_raw=$(curl -fsS --max-time 6 "https://tgftp.nws.noaa.gov/data/observations/metar/stations/SBPA.TXT" 2>/dev/null)
if [[ -n $metar_raw ]]; then
    metar_time=$(echo "$metar_raw" | head -1 | xargs)
    metar_line=$(echo "$metar_raw" | tail -1 | xargs)
    metar_section="METAR SBPA — ${metar_time} UTC
${metar_line}"
else
    metar_section="METAR SBPA: indisponível"
fi

taf_raw=$(curl -fsS --max-time 6 "https://tgftp.nws.noaa.gov/data/forecasts/taf/stations/SBPA.TXT" 2>/dev/null)
if [[ -n $taf_raw ]]; then
    taf_time=$(echo "$taf_raw" | head -1 | xargs)
    taf_body=$(echo "$taf_raw" | tail -n +2 | sed 's/^[[:space:]]*/  /')
    taf_section="TAF SBPA — ${taf_time} UTC
${taf_body}"
else
    taf_section="TAF SBPA: indisponível"
fi

tooltip="${weather_line}

${metar_section}

${taf_section}"

jq -cn --arg text "$icon" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip}'
