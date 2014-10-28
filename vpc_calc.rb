#! /usr/bin/ruby

require "ipaddr"


def add_commas(n)
    return formatted_n = n.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
end

def get_space(cidr)
    return (2 ** (32 - cidr))
end


def build_vpc( cidr, azs, subnets)

    # Set VPC constants
    reserved_ips = 5
    max_cidr = 16
    min_cidr = 28

    body = ''

    if match = cidr.match(/^(\d+\.\d+.\d+.\d+)\/(\d+)$/)
      address, prefix = match.captures
    else
      body = '<p>Invalid CIDR format (should be xxx.xxx.xxx.xxx/yy)'
      return body
    end
    prefix = prefix.to_i

    if prefix > min_cidr or prefix < max_cidr
        body = '<p>VPC CIDR prefix must be between /16 and /28'
        return body
    end

    ip_space = get_space(prefix)
    body = body + "<p>Total address space is #{add_commas(ip_space)} addresses"
    total_subnets = subnets * azs
    cidr_slice = (prefix + (Math.log(total_subnets,2)).ceil).to_i
    body = body + "<p>Each subnet is /#{cidr_slice}"
    if cidr_slice > 29 
        body += '<p>Subnets are too small (min /29) to include reserved IPs.'
        return body
    end
    sub_space = get_space(cidr_slice)
    buffer_space = ip_space - (sub_space * total_subnets)
    sub_ip_space = IPAddr.new("#{address}/#{cidr_slice}")
    body += "<table><tr><td>&nbsp;</td>"
    az_range = (1..azs)
    az_range.each() do |az|
        body += "<td>AZ #{az}</td>"
    end
    sub_range = (1..subnets)
    sub_range.each() do |sub|
        body += "</tr><tr><td>Subnet #{sub}</td>"
        az_range = (1..azs)
        az_range.each() do |az|
            first_ip = sub_ip_space.to_range.begin
            reserved_ip = first_ip
            reserved_range = (1...reserved_ips-1)
            reserved_range.each() do 
              reserved_ip = reserved_ip.succ
            end
            last_ip  = sub_ip_space.to_range.end
            body = body + "<td>#{first_ip} - #{last_ip}<br/>Reserved: #{first_ip} - #{reserved_ip} and #{last_ip}<br/>Available: #{add_commas(sub_space - reserved_ips)} addresses</td>"
            sub_ip_space = IPAddr.new("#{sub_ip_space.to_range.end.succ}/#{cidr_slice}")
        end
    end
    body += "</tr></table>"
    body = body + "<p>#{buffer_space} addresses remain in reserve"
end

cidr = "10.0.0.0/16"
subnets = 3
azs = 2
output = build_vpc(cidr,azs,subnets)
print output
