var uuid = require('node-uuid');

exports.pub_port = process.env.VMC_APP_PORT || 3000;
exports.pub_host = "0.0.0.0";

exports.sub_port = process.env.VMC_APP_PORT || 3001;
exports.sub_host = "0.0.0.0";

var vcap;
if (process.env.VCAP_SERVICES) {
    vcap = JSON.parse(process.env.VCAP_SERVICES);
}

if (vcap) {
    exports.amqp_urls = [];
    var l = vcap['rabbitmq-srs-2.4.1'] || [];
    for(var i = 0; i < l.length; i++) {
        var v = l[i];
        exports.amqp_urls.push(v.credentials.url);
    }
} else {
    exports.amqp_urls = ['amqp://guest:guest@localhost:5672/'];
}

if (vcap) {
    exports.redis = vcap['redis-2.2'][0].credentials;
} else {
    exports.redis ={
        "hostname": "127.0.0.1",
        "port": 6379,
        "password": "guest"
    };
}

exports.id = process.env.VMC_APP_ID || uuid();

console.log(exports);
