http = require('http')
config = require('../config')
amqp = require('amqp')

utils = require('./utils')


stats = []


redis_client = null

exports.run = ->
    console.log('amqp', config.amqp_urls)
    for vurl in config.amqp_urls
        do ->
            url = vurl
            conn = amqp.createConnection(utils.fixupAmqpUrl(url))
            conn.on 'ready', ->
                conn.exchange 'pub-exchange', {type:'topic'}, (exc) ->
                    console.log('pub exchange', ''+exc)
                    s = {send_count:0, url:url}
                    stats.push( s )
                    do_send = ->
                        s.send_count += 1
                        exc.publish("" + utils.randomNumber(100), 'blah')
                        setTimeout(do_send, utils.randomNumber(70, 130))
                    do_send()

    utils.createRedis (client) ->
        redis_client = client
        utils.uploadPeriodically(client, 'publishers', config.id, -> {updated:(new Date).getTime(), stats:stats})

    server = http.createServer()
    server.addListener('request', utils.default_handler(-> redis_client))
    console.log("[*] Pub listening on", config.pub_port, config.pub_host);
    server.listen(config.pub_port, config.pub_host)

