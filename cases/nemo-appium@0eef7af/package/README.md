# nemo-appium

## Usage

Add to your nemo plugins. Be sure to send the path to your appium executable. Be sure to register it as a "pre-driver" 
plugin (see: https://github.com/paypal/nemo#plugins):

```
"appium": {
      "module": "nemo-appium",
      "priority": 99,
      "arguments": ["/Users/medelman/.nvm/current/bin/appium"]
    }
```

If you don't have appium running, the plugin will start the appium server.

### Interface

The plugin adds `nemo.appium.process` and `nemo.appium.kill`.


**nemo.appium.process** is a reference to the 
[ChildProcess](https://nodejs.org/api/child_process.html#child_process_class_childprocess) object started for `appium`.

**nemo.appium.kill** is a function which wraps `ChildProcess#kill` for the appium process.



## Log/debug

In order to see log/debug messages, set `DEBUG=nemo-appium*` into your shell environment.

## Related plugins

Consider using this along with `nemo-wd-bridge`:
[https://github.com/paypal/nemo-wd-bridge](https://github.com/paypal/nemo-wd-bridge)