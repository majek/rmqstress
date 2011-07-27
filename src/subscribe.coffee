http = require('http')
config = require('../config')
amqp = require('amqp')

utils = require('./utils')

stats = []

redis_client = null

exports.run = ->
    console.log('amqp', config.amqp_urls)
    for url in config.amqp_urls
        conn = amqp.createConnection(utils.fixupAmqpUrl(url))
        conn.on 'ready', ->
            conn.exchange 'pub-exchange', {type:'topic'}, (exc) ->
                queue = conn.queue config.id, {exclusive:true}, ->
                    queue.bind('pub-exchange', '*')
                    s = {recv_count:0, url:url}
                    stats.push( s )
                    do_recv = (message) ->
                        s.recv_count += 1
                    queue.subscribe({ack:false}, do_recv)


    utils.createRedis (client) ->
        redis_client = client
        utils.uploadPeriodically(client, 'subscribers', config.id, -> {updated:(new Date).getTime(), stats:stats})

    server = http.createServer()
    server.addListener('request', utils.default_handler(-> redis_client))
    console.log("[*] Sub listening on", config.sub_port, config.sub_host);
    server.listen(config.sub_port, config.sub_host)

