[
    'Saint Mary',
    'Saint John',
    'Trinity',
    'Saint Martin',
    'Saint Ouen',
    'Grouville',
    'Saint Peter',
    'Saint Lawrence',
    'Saint Clement',
    'Saint Brélade',
    'St. Saviour',
    'Saint-Hélier'
].each do |parish_name|
  Parish.create!(name: parish_name)
end
