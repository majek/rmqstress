http = require('http')
config = require('../config')
amqp = require('amqp')

utils = require('./utils')
rclient = require('./rclient')


stats = [{vcap_app_host: process.env.VCAP_APP_HOST}]

exports.run = ->
    total_send_count = 0
    for vurl in config.amqp_urls
        do ->
            to = 0
            url = vurl
            console.log('[.] pub', url)
            conn = amqp.createConnection(utils.fixupAmqpUrl(url))
            conn.on 'ready', ->
                conn.exchange 'pub-exchange', {type:'topic'}, (exc) ->
                    s = {
                        send_count:0
                        url:url
                    }
                    stats.push( s )
                    do_send = ->
                        s.send_count += 1
                        total_send_count += 1
                        s.delay = to
                        exc.publish("r", '.',
                                {immediate: true})
                        if to
                            to -= 1
                            setTimeout(do_send, to)
                        else
                            process.nextTick(do_send)
                    do_send()
                    exc.on 'basicReturn', (m)->
                        to = if to < 100 then to + 5 else to
                        return true

    last_send_count = 0
    periodically = ->
        d = total_send_count - last_send_count
        last_send_count = total_send_count
        rclient.incrTotal('pub', d)
    setInterval(periodically, 100)

    rclient.uploadPeriodically 'publishers', config.id, ->
            {updated:(new Date).getTime(), stats:stats}

    server = http.createServer()
    server.addListener('request', utils.default_handler)
    console.log("[*] Pub listening on", config.pub_port, config.pub_host);
    server.listen(config.pub_port, config.pub_host)

