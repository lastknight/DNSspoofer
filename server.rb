
require 'resolv'


@srvhost = "0.0.0.0"
@port = 53
@realdns = "78.47.222.141"

# MacOS X workaround
::Socket.do_not_reverse_lookup = true

@sock = ::UDPSocket.new()
@sock.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, 1)
@sock.bind(@SRVHOST, @port)
@run = true

@hosts = {}

# Wrap in exception handler   
puts "starting server...\ndone!\n\n"
begin
  while @run
    packet, addr = @sock.recvfrom(65535)
    
    if (packet.length == 0)
      break
    end
    
    request = Resolv::DNS::Message.decode(packet)
    
    # W: Go ahead and send it to the real DNS server and
    #    get the response
    sock2 = ::UDPSocket.new()
    sock2.send(packet, 0, @realdns, 53) 
    packet2, addr2 = sock2.recvfrom(65535)
    sock2.close()

    # puts "REQUEST\n#{request.inspect}" 

    real_response = Resolv::DNS::Message.decode(packet2)
    fake_response = Resolv::DNS::Message.new()

    fake_response.qr = 1 # Recursion desired
    fake_response.ra = 1 # Recursion available
    fake_response.id = real_response.id

    real_response.each_question { |name, typeclass|
      fake_response.add_question(name, typeclass)
      prepend = ""
      if @hosts.has_key?(name)
        @hosts[name] = @hosts[name] + 1
      else
        @hosts[name] = 1
        prepend = "!!!!"
      end
      puts "[#{Time.now}] - #{addr[2]} -> #{typeclass.to_s.gsub("Resolv::DNS::Resource::", '')} - #{prepend}#{name} (#{@hosts[name]})"
    }

    # Poisoned
    poisoned = Hash.new
    poisoned["www.example.com"] = "127.0.0.3"

    real_response.each_answer { |name, ttl, data| 
      Thread.new {
        replaced = false
        poisoned.each { |e|
          if name.to_s == e[0]
            case data.to_s 
            when /IN::A/
              data = Resolv::DNS::Resource::IN::A.new(e[1])
              replaced = true
            when /IN::MX/
              data = Resolv::DNS::Resource::IN::MX.new(10,Resolv::DNS::Name.create(e[1]))
              replaced = true
            when /IN::NS/
              data = Resolv::DNS::Resource::IN::NS.new(Resolv::DNS::Name.create(e[1]))
              replaced = true
            when /IN::PTR/
              # Do nothing
              replaced = true
            else
              # Do nothing
              replaced = true
            end
          end
          break if replaced
        }
        fake_response.add_answer(name,ttl,data)         
      }
    }

    real_response.each_authority { |name, ttl, data|
      poisoned.each { |e|
        if name.to_s == e[0] 
          data = Resolv::DNS::Resource::IN::NS.new(Resolv::DNS::Name.create(e[1]))
          break
        end
      }
      fake_response.add_authority(name,ttl,data)
    }

    response_packet = fake_response.encode()
    #puts "RESPONSE\n#{fake_response.inspect}" 

    @sock.send(response_packet, 0, addr[3], addr[1])
  end

  # Make sure the socket gets closed on exit
rescue ::Exception => e
  puts ("fakedns: #{e.class} #{e} #{e.backtrace}")
ensure
  @sock.close
end

