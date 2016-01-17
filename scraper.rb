#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'open-uri/cached'
require 'colorize'
require 'pry'
require 'csv'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_people(url)
  page = noko_for url
  page.css('div#cvList a/@href').each do |href|
    scrape_person(URI.join(url, href))
  end
end

def scrape_person(url)
  person = noko_for(url)

  sort_name = person.css('div.cvTitle').text.tidy
  given_names, family_names = sort_name.split(/[[:space:]]/).partition { |w| w == w.upcase }

  sites = sites = person.css('div.cvData a/@href').map(&:text).map(&:tidy).reject { |s| s.include? 'mailto:' }

  data = { 
    id: url.to_s[/cid=(\d+)/, 1],
    name: (given_names + family_names).join(' '),
    given_name: given_names.join(' '),
    family_name: family_names.join(' '),
    sort_name: sort_name,
    image: person.xpath('//img[@id="cvImage"]/@src').text,
    email: person.css('div.cvData a[href*="mailto:"]').text.tidy,
    website: sites.find { |s| s.include? 'parliament.mn' },
    facebook: sites.find { |s| s.include? 'facebook' },
    twitter: sites.find { |s| s.include? 'twitter' },
    source: url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id], data)
end

scrape_people 'http://www.parliament.mn/en/who?type=3'
