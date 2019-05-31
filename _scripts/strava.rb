#!/usr/bin/env ruby

require 'strava/api/v3'
require 'json'

ATHLETE_ID = 6925704

@client = Strava::Api::V3::Client.new(
  access_token: ENV['STRAVA_TOKEN']
)

# Generate _data/stats.yml
stats = @client.totals_and_stats(ATHLETE_ID)

count = stats['all_ride_totals']['count'] + stats['all_run_totals']['count']
distance = (stats['all_ride_totals']['distance'] +
            stats['all_run_totals']['distance'])
moving_time = stats['all_ride_totals']['moving_time'] +
              stats['all_run_totals']['moving_time']
elapsed_time = stats['all_ride_totals']['elapsed_time'] +
              stats['all_run_totals']['elapsed_time']
elevation_gain = stats['all_ride_totals']['elevation_gain'] +
                 stats['all_run_totals']['elevation_gain']

totals = {
  count: count,
  distance: distance,
  moving_time: moving_time,
  elapsed_time: elapsed_time,
  elevation_gain: elevation_gain,
}

File.open('_data/stats.json', 'w') do |f|
  f.puts stats.merge(totals: totals).to_json
end

# Generate _data/races.geojson
races = []
page = 1

while 1
  options = {
    page: page,
    per_page: 200,
    workout_type: 1,
    type: 'Ride,Run,Hike'
  }

  activities = @client.list_athlete_activities(options)
  break if activities.count < 1

  activities.each do |a|
    next if a['workout_type'] != 1

    race = {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [
          # Geojson spec
          a['start_longitude'],
          a['start_latitude']
        ]
      },
      'properties': {
        'Race name': a['name'],
        'Date': a['start_date'],
        'Distance (km)': (a['distance'] / 1000).round(2),
        'Average speed (km/h)': (a['average_speed'] * 3.6).round(2),
        'Max speed (km/h)': (a['max_speed'] * 3.6).round(2),
        'Elevation high (m)': a['elev_high'].round,
        'Elevation low (m)': a['elev_low'].round,
        'Total elevation gain (m)': a['total_elevation_gain'].round,
        'Coordonnées (lat,lng)': a['end_latlng'],
        'marker-symbol': 'pitch',
        'marker-size': 'medium'
      }
    }

    races << race
  end

  page += 1
end

races = {
  'type': 'FeatureCollection',
  'features': races
}

File.open('_data/races.geojson', 'w') do |f|
  f.puts races.to_json
end
