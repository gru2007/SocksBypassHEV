# SocksBypassHEV → VK TURN Proxy (iOS)

Этот проект переделан из SOCKS5-сервера в основу для интеграции сторонней библиотеки `vk-turn-proxy`.

## Что изменено

- Удалена логика запуска SOCKS5/HEV из iOS-приложения.
- Добавлен `Packet Tunnel Network Extension` (`TurnProxyExtension`).
- Расширение запускает бинарник `vk-turn-client` (проект `cacggghp/vk-turn-proxy`) с параметрами из `NETunnelProviderProtocol.providerConfiguration`.
- Добавлен скрипт сборки под `iphoneOS`.

## Сборка клиента vk-turn-proxy под iphoneOS

```bash
./Scripts/build_vk_turn_client.sh
```

Скрипт:
1. Клонирует/обновляет `https://github.com/cacggghp/vk-turn-proxy` в `ThirdParty/vk-turn-proxy`.
2. Выполняет сборку:

```bash
GOOS=ios GOARCH=arm64 CGO_ENABLED=1 go build -o TurnProxyExtension/Tools/vk-turn-client ./client
```

## Конфигурация запуска в приложении

По умолчанию приложение сохраняет параметры:

- `peer = 127.0.0.1:56000`
- `listen = 127.0.0.1:9000`
- `threads = 16`
- `transport = tcp`
- `vk_link = https://vk.com/call/join/REPLACE_ME`

Замените `vk_link` и `peer` перед использованием.

## Важно

Для реального запуска на устройстве дополнительно потребуются:
- entitlement'ы Network Extension,
- корректные `App Group`/подписи,
- разрешение на Packet Tunnel от Apple для вашего Team.
