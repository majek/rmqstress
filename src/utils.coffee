config = require('../config')
url = require('url')
rclient = require('./rclient')

exports.randomNumber = (a, b) ->
    if typeof b is 'undefined'
        [a, b] = [0, a]
    return a + (Math.floor(Math.random() * (b-a)))

exports.default_handler = (req, res) ->
    res.setHeader('Content-Type', 'text/plain')
    res.writeHead(200)
    rclient.getTotals ['pub', 'sub'], (r) ->
        res.write(JSON.stringify(r, null, 4))
        res.write('\r\n\r\n')
        rclient.queryRedis 'subscribers', (r) ->
            res.write('Subscribers\r\n')
            res.write(JSON.stringify(r, null, 4))
            res.write('\r\n\r\n')
            rclient.queryRedis 'publishers', (r) ->
                res.write('Publishers\r\n')
                res.write(JSON.stringify(r, null, 4))
                res.write('\r\n\r\n')
                res.end()

exports.fixupAmqpUrl = (amqp_url) ->
    u = url.parse(amqp_url)
    r = {
        host:u.hostname,
        port:u.port,
        login:u.auth.split(':')[0],
        password:u.auth.split(':')[1],
        vhost:u.pathname.slice(1) or '/'
    }
    return r