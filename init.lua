local DEVICE = "nips"

local station_cfg={}
station_cfg.ssid="glamslam-internal"
station_cfg.pwd="k6TChCtpafubLht"

wifi.setmode(wifi.STATION)
wifi.sta.config(station_cfg)

function check_wifi()
 local ip = wifi.sta.getip()
 
 if(ip==nil) then
    print(".")
    tmr.alarm(0,500,1,check_wifi)
 else
    tmr.stop(0)
    print("Connected to AP: " .. ip)
    wifi_ready()
 end 
end



function initStrip()
   ws2812_effects.init(buffer)
   ws2812_effects.set_color(75,75,255)
   ws2812_effects.set_brightness(100)
   ws2812_effects.set_speed(200)
  -- ws2812.write(string.char(50, 0, 0, 0, 50, 0, 0,0,50))
  -- init the effects module, set color to red and start blinking
  ws2812_effects.set_mode("larson_scanner")
  --ws2812_effects.set_mode("fire_intense")
  ws2812_effects.start()

  print( "written");
end


function dimBuffer()
  local psu_current_ma = 1000
  local led_current_ma = 20
  local led_sum = psu_current_ma * 255 / led_current_ma
  local p = buffer:power()
  if p > led_sum then
    buffer:mix(256 * led_sum / p, buffer) -- power is now limited
  end
end

function initServer()
	udpSocket = net.createUDPSocket()
	udpSocket:listen(3031)

    local fullData = ""
	udpSocket:on("receive", function(s, data, port, ip)
--                    print(string.format("received '%s'", data))
                    fullData = fullData .. data
                    fullData = unloadData(fullData, parse_command)
	end)
    
    function unloadData(data, callback)
       local pos = string.find(data, "\n")
       if (pos) then
          local command = string.sub(data, 0, pos - 1)
          callback(command)
          return unloadData(string.sub(data, pos + 1, string.len(data)), callback)
       else
          return data
       end
    end


	port, ip = udpSocket:getaddr()
	print(string.format("UDP socket listening on %s:%d", ip, port))
end

buffer = ws2812.newBuffer(144, 3)
r = 3
g = 3
b = 15

function parse_command(command)
   print("parsing: '" .. command .. "'")
   
   local decoder = sjson.decoder()
   decoder:write(command)

   local c = decoder:result()
   
   if c["r"] then r = c["r"] end
   if c["g"] then g = c["g"] end 
   if c["b"] then b = c["b"] end 

   if c["r"] or c["g"] or c["b"] then
      ws2812_effects.set_color(g, r, b)
   end

   if (c["brightness"]) then
      print('set brightness', c["brightness"])
      ws2812_effects.set_brightness(c["brightness"])
   end

   if (c["effect"]) then
      print('set effect', c["effect"])
      ws2812_effects.set_mode(c["effect"])
      ws2812_effects.start()
   end
   
   if (c["speed"]) then
      print('set speed',c["speed"] * 2)
      ws2812_effects.set_speed(c["speed"] * 2)
   end

--    if (c["color"]) then
--       print('set color', r, g, b)
--       ws2812_effects.set_color(g, r, b)
-- --      ws2812_effects.stop()
-- --      buffer:fill(g, r, b)
-- --      dimBuffer()
-- --      ws2812.write(buffer)
--    end


end

function wifi_ready()
 initStrip()
 initServer()

end

print('Initializing Strip')


ws2812.init()
buffer:fill(r, g, b)
dimBuffer()
ws2812.write(buffer)

print('Connecting')

wifi.sta.autoconnect(1)

tmr.alarm(0,500,1,check_wifi)


