# SuperKore OpenKore plugin: `wsbridge`

## Install

1. Copy this folder to `<openkore>/plugins/wsbridge/`
2. In `control/sys.txt`:

```
loadPlugins 2
loadPlugins_list wsbridge
```

(or append `wsbridge` to an existing `loadPlugins_list`)

3. In profile `config.txt`:

```
wsBridge 1
wsBridge_host 127.0.0.1
wsBridge_port 9901
wsBridge_proxy wss://m.example-ro.com:8443
```

`wsBridge_port` must match a `--listen` port on the SuperKore connector.

## Flow

OpenKore → TCP connector → WSS gateway (VPS) → RoPlay `socketProxy`
