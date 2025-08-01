# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 0) do
  # This application uses solid adapters (solid_cache, solid_queue, solid_cable)
  # which manage their own schemas in separate files:
  # - db/cache_schema.rb (for solid_cache)
  # - db/queue_schema.rb (for solid_queue) 
  # - db/cable_schema.rb (for solid_cable)
  #
  # The weather application doesn't use traditional ActiveRecord models
  # and instead relies on external APIs (Open-Meteo, Nominatim) for data.
end
