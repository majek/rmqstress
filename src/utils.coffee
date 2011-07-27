redis = require('redis')
config = require('../config')
url = require('url')

exports.randomNumber = (a, b) ->
    if typeof b is 'undefined'
        [a, b] = [0, a]
    return a + (Math.floor(Math.random() * (b-a)))

exports.createRedis = (cb) ->
    console.log('redis1:', config.redis.port, config.redis.hostname)
    client = redis.createClient(config.redis.port, config.redis.hostname)
    client.on 'error', (e) -> console.log('error', e)
    console.log('client1')
    if not config.redis.password
        throw Error("configure redis to use pass")
    client.auth config.redis.password, ->
            console.log('redis ok');
            cb(client)

exports.uploadPeriodically = (client, key, id, fun) ->
    publish = ->
        client.hset(key, id, JSON.stringify(fun()))
        setTimeout(publish, 1000)
    publish()

queryRedis = exports.queryRedis = (client, key, fun) ->
    client.hgetall key, (err, obj) ->
        r = {}
        for id of obj
            v = JSON.parse(obj[id])
            if not v.updated or ((new Date).getTime() - v.updated) > 5000
                client.hdel(key, id)
            else
                r[id] = v.stats
        fun(r)

exports.default_handler = (get_client) ->
    return (req, res) ->
        res.setHeader('Content-Type', 'text/plain')
        res.writeHead(200)
        queryRedis get_client(), 'subscribers', (r) ->
            res.write('Subscribers\r\n')
            res.write(JSON.stringify(r, null, 4))
            res.write('\r\n\r\n')
            queryRedis get_client(), 'publishers', (r) ->
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
    console.log('amqp url:', r)
    return r