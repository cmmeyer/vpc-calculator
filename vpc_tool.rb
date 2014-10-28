#1 /usr/bin/ruby

require "ipaddr"
require 'sinatra'
require_relative 'vpc_calc'

class CidrToolApp < Sinatra::Base
  get '/:prefix/:azs/:subs' do | prefix, azs, subs |
    address = '10.0.0.0'
    @cidr = address + '/' + prefix
    @azs = azs.to_i
    @subs = subs.to_i
    @body = build_vpc(@cidr,@azs,@subs)
    haml :index, :format => :html5
  end

  post '/' do
    @cidr = params[:cidr]
    @azs = params[:azs].to_i
    @subs = params[:subs].to_i
    @body = build_vpc(@cidr,@azs,@subs)
    haml :index, :format => :html5
  end

  get '/?*?' do
    haml :index, :format => :html5
  end
end

