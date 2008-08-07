dir = File.dirname(__FILE__)
Dir["#{dir}/extensions/*.rb"].each do |file|
  require file
end
