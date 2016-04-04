require 'json'
require 'dnsruby'
require 'resolv-replace'
require 'fileutils'
include Dnsruby

class BindDocker

  @@zonefiles = []
  @@named_conf = nil
  IMAGE='clcloud/dnsuats'
  CONTAINER_NAME='dns-funtime'

  def self.filename file
    File.split(file)[1]
  end

  def self.run!
    Dir.mktmpdir do |dir|
      FileUtils.cp @@named_conf, dir, {}
      FileUtils.cp @@zonefiles, dir, {}
      build_docker_file dir
      Dir.chdir(dir) do
        `docker build -t #{IMAGE} .`
        `docker run -d -p 1053:53/udp -p 1053:53/tcp --name=#{CONTAINER_NAME} #{IMAGE}`
      end
    end
  end

  def self.stop!
    `docker rm -f #{CONTAINER_NAME} > /dev/null 2>&1`
  end

  def self.resolve address
    Resolv.getaddress(address).to_s
  end

  def self.add_zonefile zonefile_path
    @@zonefiles.push File.new(zonefile_path)
  end

  def self.clear_zonfiles
    @@zonefiles.clear
  end

  def self.named_conf named_conf_path
    @@named_conf = File.new(named_conf_path)
  end

  def self.build_docker_file tmp_dir
    File.open(tmp_dir + "/Dockerfile", 'w') do |file|
      file.write(docker_preamble)
      @@zonefiles.each do |zonefile|
        file.write("COPY #{filename(zonefile)} /var/cache/bind/#{filename(zonefile)}\n")
      end
      file.write("COPY #{filename(@@named_conf)} /etc/bind/#{filename(@@named_conf)}\n")
      file.close
    end
  end

  def self.docker_preamble
    <<-HEREDOC
FROM phusion/baseimage:0.9.18
MAINTAINER storage-solutions@ctl.io

ENV DATA_DIR=/data \
    BIND_USER=bind


RUN rm -rf /etc/apt/apt.conf.d/docker-gzip-indexes \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 dnsutils \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 53/udp
EXPOSE 53/tcp
VOLUME ["${DATA_DIR}"]
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf"]

    HEREDOC
  end


  def self.docker_ip
    if (/darwin/ =~ RUBY_PLATFORM)
      `docker-machine ip default`.strip
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
    resolv = Resolv::DNS.new(nameserver_port:[[BindDocker.docker_ip, 1053]],
                             search: [default_search],
                             ndots: 1)

    remove_const :DefaultResolver
    const_set :DefaultResolver, self.new([Resolv::Hosts.new, resolv])
  end

end
