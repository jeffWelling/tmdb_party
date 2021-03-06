# gem 'httparty'
require 'rubygems'
require 'httparty'

current_dir=File.expand_path(File.dirname(__FILE__))
unless $LOAD_PATH.first==(current_dir)
  $LOAD_PATH.unshift(current_dir)
end
 
require "tmdb_party/core_extensions"
require "tmdb_party/httparty_icebox"
require "tmdb_party/attributes"
require "tmdb_party/video"
require "tmdb_party/genre"
require "tmdb_party/person"
require "tmdb_party/image"
require "tmdb_party/movie"
require "../memoizable/lib/memoizable.rb"

module TMDBParty
  class Base
    include HTTParty
    include HTTParty::Icebox
    include Memoizable
    cache :store => 'file', :timeout => 120, :location => Dir.tmpdir

    base_uri 'http://api.themoviedb.org/2.1'
    format :json

    def readFile filename, maxlines=0
      i=0
      read_so_far=[]
      f=File.open(File.expand_path(filename), 'r')
      while (line=f.gets)
        break if maxlines!=0 and i >= maxlines
        read_so_far << line and i+=1
      end
      read_so_far
    end
    
    def initialize(key=nil)
      !key.nil? ? (@api_key = key) : (@api_key= readFile('apikey.txt').first.strip)
    end
    
    def default_path_items
      path_items = ['en']
      path_items << 'json'
      path_items << @api_key
    end
    
    def search(query)
      data = self.class.get("/Movie.search/" + default_path_items.join('/') + '/' + URI.escape(query))
      if data.class != Array || data.first == "Nothing found."
        []
      else
        data.collect { |movie| Movie.new(movie, self) }
      end
    end
    memoize :search
    
    def imdb_lookup(imdb_id)
      data = self.class.get("/Movie.imdbLookup/" + default_path_items.join('/') + '/' + imdb_id)
      if data.class != Array || data.first == "Nothing found."
        nil
      else
        Movie.new(data.first, self)
      end
    end
    
    def get_info(id)
      data = self.class.get("/Movie.getInfo/" + default_path_items.join('/') + '/' + id.to_s)
      Movie.new(data.first, self)
    end
  end
end
