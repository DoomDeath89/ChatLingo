# ChatLingo

Addon para WoW Classic Era (1.15.x) que traduce automaticamente el chat entrante usando Google Translate via un companion app externo.

## Arquitectura

### Addon (Lua)
- `ChatLingo.lua` — Nucleo: hookea eventos `CHAT_MSG_*`, encola mensajes, pollea resultados via `OnUpdate`
- `ChatLingoConfig.lua` — Frame de configuracion propio (sin templates rotos), dropdown de idiomas, checkboxes por canal, slider de polling, botones
- `ChatLingo.toc` — Manifiesto, Interface 11508, SavedVariables `ChatLingoDB`

### Companion (Python)
- `companion/translator.py` — Monitorea `WoWChatLog.txt`, traduce via Google Translate API, inyecta resultado al chat de WoW simulando `/script ChatFrame1:AddMessage(...)` via SendKeys (PowerShell)

## Que funciona
- [x] Addon carga sin errores en WoW Classic Era 1.15.8
- [x] Slash command `/cl` abre/cierra frame de configuracion
- [x] Frame de config con dropdown de idioma, checkboxes de canales, slider de polling, botones Limpiar/Reset/Cerrar
- [x] Companion encuentra el chat log, traduce texto via Google Translate
- [x] Companion inyecta traduccion al chat de WoW via keystrokes (SendKeys)
- [x] Debug interno via `ChatLingoDB.debug[]` (array en SavedVariables)
- [x] Repo Git publico en GitHub

## Que falta / Problemas conocidos
- [ ] **Tiempo real:** El addon usa SavedVariables para la cola, pero WoW solo persiste SavedVariables al recargar. El companion actualmente salta el addon y lee directo del chat log — la cola del addon queda huérfana. Habria que unificar: el addon podria escribir a un archivo via mecanismo alternativo, o el companion podria inyectar datos a la memoria del addon via consola.
- [ ] **Filtrado por canal:** El companion traduce TODO lo que aparece en el chat log. El addon tiene config de canales, pero el companion no la respeta.
- [ ] **Cache de traducciones:** El addon tiene `config.cache` pero el companion no persiste cache entre sesiones.
- [ ] **Slash command a veces no responde:** En pruebas iniciales, `/cl` mostraba "Escribe /ayuda..." en vez de ejecutar la funcion. Se corrigio con `pcall` en `RegisterEvent`, pero podrian quedar casos borde.
- [ ] `CHAT_MSG_TRADE` no existe en Vanilla (era de TBC+). Se maneja con `pcall`, pero habria que filtrarlo de la lista de eventos.
- [ ] **Companion fragil:** SendKeys requiere la ventana de WoW activa/visible. Si el usuario cambia de ventana, la inyeccion puede ir a otra aplicacion.
- [ ] **No discrimina mensajes propios:** El companion traduce incluso los mensajes que escribe el usuario.
- [ ] **Logueo:** No hay manejo de errores robusto en el companion (timeouts de red, parseo de chat log).

## Instalacion

1. Copiar `ChatLingo/` a `_classic_era_\Interface\AddOns\`
2. Activar el addon en el menu de addons de WoW
3. En WoW, ejecutar `/console chatlog 1` (una vez por sesion)
4. Ejecutar el companion: `python companion/translator.py`
5. Para configurar, usar `/cl` en WoW

## Dependencias

- Python 3 con `requests`
- WoW Classic Era con chat logging activado (`/console chatlog 1`)
