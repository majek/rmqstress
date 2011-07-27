var subscribe = require('./lib/subscribe');
var publish = require('./lib/publish');

if (!process.env.VMC_APP_NAME) {
    publish.run();
    subscribe.run();
} else {
    if (process.env.VMC_APP_NAME.indexOf('pub') !== -1) {
        publish.run();
    }
    if (process.env.VMC_APP_NAME.indexOf('sub') !== -1) {
        subscribe.run();
    }
}
