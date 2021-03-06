require 'rails_helper'
require 'fileutils'

feature 'Devise restricts features for unauthenticated users', type: :feature, js: true do
  
  before(:all) do
    dump_test_bib_ids('./spec/fixtures/sample_bib_ids.txt')
    system 'rake db:seed'
  end

  after(:all) do
    Event.destroy_all
    DumpFileType.destroy_all
    Locations::Library.destroy_all
    Locations::HoldingLocation.destroy_all
    Locations::DeliveryLocation.destroy_all
    Locations::HoursLocation.destroy_all
    Resque.redis.del "queue:default"
  end

  unless ENV['CI']
    scenario 'Anyone can retrieve an event dump' do
      event = Event.last
      visit "/events/#{event.id}"
      click_link "Dump"
    end

    scenario "anyone can retrieve JSON feeds for events" do
      visit "/events.json"
    end

    scenario "only authenticated users can delete events" do
      visit "/events"
      click_link "Delete"
      find("div.alert", text: I18n.t("devise.failure.unauthenticated"))
    end
  end

  ["libraries", "holding_locations", "delivery_locations",
    "hours_locations"].each_with_index do |data_type, i|
    scenario "anyone can retrieve JSON feeds for #{data_type}" do
      visit "/locations/#{data_type}.json"
    end

    scenario "only authenticated users can create new #{data_type}" do
      visit "/locations/#{data_type}"
      find("a[href='/locations/#{data_type}/create']").click
      find("div.alert", text: I18n.t("devise.failure.unauthenticated"))
    end 
  end

  def dump_test_bib_ids(bibs)
    dump = nil
    Event.record do |event|
      dump = Dump.create(dump_type: DumpType.find_by(constant: 'BIB_IDS'))
      dump.event = event
      dump_file = DumpFile.create(dump: dump, dump_file_type: DumpFileType.find_by(constant: 'BIB_IDS'))
      FileUtils.cp bibs, dump_file.path
      dump_file.save
      dump_file.zip
      dump.dump_files << dump_file
      dump.save
    end
    dump
  end
end
