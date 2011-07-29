config = require('../config')
redis = require('redis')

client = exports.client = \
    redis.createClient(config.redis.port, config.redis.hostname)

client.on 'error', (e) -> console.log('redis error', e.stack, e)
if config.redis.password
    client.auth(config.redis.password)


exports.uploadPeriodically = (key, id, fun) ->
    publish = ->
        client.hset(key, id, JSON.stringify(fun()))
        setTimeout(publish, 1000)
    publish()


exports.queryRedis = (key, fun) ->
    client.hgetall key, (err, obj) ->
        r = {}
        for id of obj
            v = JSON.parse(obj[id])
            if not v.updated or ((new Date).getTime() - v.updated) > 5000
                client.hdel(key, id)
            else
                r[id] = v.stats
        fun(r)

exports.incrTotal = (key, val) ->
    client.incrby(key, val)
    skey = key + '.'+ Math.floor((new Date).getTime()/1000)
    client.incrby skey, val, (err, v) ->
        if v is val
            client.expire(skey, 120)

exports.getTotals = (keys, fun) ->
    now = Math.floor((new Date).getTime()/1000)
    keys2 = []
    getters = []
    r = {}
    for _key in keys
        do ->
            key = _key
            r[key] = {total:null, per_second:[]}
            keys2.push( key )
            getters.push (v) -> r[key].total = v
            for i in [now...now-10]
                keys2.push( key+ '.' + i )
                getters.push (v) -> r[key].per_second.push(v)
    client.mget keys2, (err, vals) ->
        for j in [0...vals.length]
            getters[j](Number(vals[j]))
        fun(r)