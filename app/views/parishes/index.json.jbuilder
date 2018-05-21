json.cache! :constituencies, expires_in: 1.hour do
  @parishes.each do |parish|
    json.set! parish.ons_code do
      json.mp parish.mp_name
      json.party parish.party
      json.parish parish.name
      json.ons_code parish.ons_code
    end
  end
end
