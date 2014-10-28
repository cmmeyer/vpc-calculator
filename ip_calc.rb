#! /usr/bin/ruby

require "ipaddr"

address = '0.0.0.0'
prefix = nil
reserved_ips = 5
max_cidr = 16
min_cidr = 28

def add_commas(n)
	return formatted_n = n.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
end

def get_space(cidr)
	return (2 ** (32 - cidr))
end

def get_cidr()
	print "VPC CIDR [x.x.x.x/x] : "
	cidr = $stdin.gets.chomp

	if match = cidr.match(/(\d+\.\d+.\d+.\d+)\/(\d*)/)
	  address, prefix = match.captures
	end
	prefix = prefix.to_i
	return address, prefix
end


while prefix == nil
	address, prefix = get_cidr()
	if prefix > min_cidr or prefix < max_cidr
		puts "VPC CIDR prefix must be between /16 and /28"
		prefix = nil
	end
end

puts "Address: #{address}  Prefix: #{prefix}"
ip_space = get_space(prefix)
puts "Total address space is #{add_commas(ip_space)} addresses)"

print "Number of AZs: "
azs = $stdin.gets.chomp.to_i

print "Subnets per AZ: "
subs = $stdin.gets.chomp.to_i
total_subs = subs * azs
cidr_slice = (prefix + (Math.log(total_subs,2)).ceil).to_i
puts "Each subnet is /#{cidr_slice}"
sub_space = get_space(cidr_slice)
buffer_space = ip_space - (sub_space * total_subs)

sub_ip_space = IPAddr.new("#{address}/#{cidr_slice}")

az_range = (1..azs)
az_range.each() do |az|
	sub_range = (1..subs)
	sub_range.each() do |sub|
		first_ip = sub_ip_space.to_range.begin
		last_ip  = sub_ip_space.to_range.end
		puts "[ AZ #{az} ] [ Subnet #{sub} ] : #{first_ip} - #{last_ip} (#{add_commas(sub_space - reserved_ips)} addresses)"
		sub_ip_space = IPAddr.new("#{sub_ip_space.to_range.end.succ}/#{cidr_slice}")
	end
end
puts "#{buffer_space} addresses remain in reserve"
