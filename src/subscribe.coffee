http = require('http')
config = require('../config')
amqp = require('amqp')

utils = require('./utils')
rclient = require('./rclient')


stats = [{vcap_app_host: process.env.VCAP_APP_HOST}]

exports.run = ->
    total_recv_count = 0
    for vurl in config.amqp_urls
        do ->
            url = vurl
            console.log('[.] sub', url)
            conn = amqp.createConnection(utils.fixupAmqpUrl(url))
            conn.on 'ready', ->
                conn.exchange 'pub-exchange', {type:'topic'}, (exc) ->
                    queue = conn.queue "the_big_queue", {autoDelete: false}, ->
                        queue.bind('pub-exchange', 'r')
                        s = {
                            recv_count:0
                            url:url
                        }
                        stats.push( s )
                        do_recv = (message) ->
                            s.recv_count += 1
                            total_recv_count += 1
                        queue.subscribe({ack:false}, do_recv)

    last_recv_count = 0
    periodically = ->
        d = total_recv_count - last_recv_count
        last_recv_count = total_recv_count
        rclient.incrTotal('sub', d)
    setInterval(periodically, 100)


    rclient.uploadPeriodically('subscribers', config.id, -> {updated:(new Date).getTime(), stats:stats})

    server = http.createServer()
    server.addListener('request', utils.default_handler)
    console.log("[*] Sub listening on", config.sub_port, config.sub_host);
    server.listen(config.sub_port, config.sub_host)

