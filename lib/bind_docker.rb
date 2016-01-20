require 'json'
require 'dnsruby'
require 'resolv-replace'
include Dnsruby

class DNSHelper

  IMAGE='clcloud/dnsuats'
  CONTAINER_NAME='dns-funtime'

  def self.run!
    `docker run -d -p 1053:53/udp -p 1053:53/tcp --name=#{CONTAINER_NAME} #{IMAGE}`
  end

  def self.stop!
    `docker rm -f #{CONTAINER_NAME} > /dev/null 2>&1`
  end

  def self.resolve address
    Resolv.getaddress(address).to_s
  end

  def self.build zonefiles_glob, named_conf
    Dir.chdir("spec/dns_files")
    `docker build -t #{IMAGE} --build-arg zonefiles_glob=#{zonefiles_glob} --build-arg named_conf=#{named_conf} .`
    Dir.chdir("../..")
  end

  def self.docker_ip
    if (/darwin/ =~ RUBY_PLATFORM)
      docker_machine_info = JSON.parse `docker-machine inspect default`
      docker_machine_info['Driver']['Driver']['IPAddress']
    else
      "127.0.0.1"
    end
  end

  def self.resolve_bucket_by_region bucket, tld
    begin
      Resolv.getaddress("#{bucket}.#{tld}").to_s
    rescue Resolv::ResolvError
      :nxdomain
    end
  end

end

class Resolv
  def self.use_uat_dns! default_search='uat-os'
    resolv = Resolv::DNS.new(nameserver_port:[[DNSHelper.docker_ip, 1053]],
                             search: [default_search],
                             ndots: 1)

    remove_const :DefaultResolver
    const_set :DefaultResolver, self.new([Resolv::Hosts.new, resolv])
  end

end
