# This migration comes from locations (originally 20160614154022)
class AddLocationsLibraryToLocationsFloors < ActiveRecord::Migration
  def change
    add_reference :locations_floors, :locations_library, index: true, foreign_key: true
  end
end
