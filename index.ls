require! { dgram, midi, lodash: { keys } }

input = new midi.input()

server = {
  host: '10.141.0.107',
  port: 3031
}


buffer = {}

send = (cmd) -> 
  buffer := buffer <<< cmd


maybeSend = ->
  if keys(buffer).length
    sendUdp(buffer)
    buffer := {}

setInterval maybeSend, 50
  
sendUdp = (cmd) ->
  console.log '>', cmd
  client = dgram.createSocket 'udp4'
  buffer = new Buffer((JSON.stringify cmd) + "\n")
  client.send buffer, 0, buffer.length, server.port, server.host, (err, bytes) ->  client.close()

r = 0
g = 0
b = 0

input.on 'message', (deltaTime, [ type, n, val] ) ->
  console.log "midi", type, n, val
  if n is 1 then send r: (r:= val)
  if n is 2 then send g: (g:= val)
  if n is 3 then send b: (b:= val)
  if n is 4
    val = 127 - val
    change = val
    makePositive = (x) -> if x < 0 then 0 else x
      
    send r: makePositive(r - val), b: makePositive(b - val), g: makePositive(g - val)

        

  if n is 6 then send brightness: val * 2
  if n is 5 then send speed: 63 + Math.round(val / 2)
    
  if n is 36 then send effect: 'random_dot'
  if n is 37 then send effect: 'flicker'
  if n is 38 then send effect: 'blink'
  if n is 39 then send effect: 'static'
    
  if n is 32 then send effect: 'larson_scanner'
  if n is 33 then send effect: 'circus_combustus'
  if n is 34 then send effect: 'random_color'
  if n is 35 then send effect: 'rainbow_cycle'

input.openPort 0


