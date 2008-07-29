dir = File.dirname(__FILE__)
Dir["#{dir}/app/models/**/*.rb"].each do |file|
  require file
end
Dir["#{dir}/app/topics/**/*.rb"].each do |file|
  require file
end
