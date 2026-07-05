# ChatLingo

Addon para WoW Classic Era (1.15.x) que traduce automaticamente el chat entrante usando Google Translate via un companion app externo.

## Arquitectura

### Addon (Lua)
- `ChatLingo.lua` — Nucleo: hookea eventos `CHAT_MSG_*`, encola mensajes, pollea resultados via `OnUpdate`
- `ChatLingoConfig.lua` — Frame de configuracion propio (sin templates rotos), dropdown de idiomas, checkboxes por canal, slider de polling, botones
- `ChatLingo.toc` — Manifiesto, Interface 11508, SavedVariables `ChatLingoDB`

### Companion (Python)
- `companion/translator.py` — Lee mensajes pendientes, traduce via Google Translate API, inyecta resultado al chat de WoW simulando `/script ChatFrame1:AddMessage(...)` via SendKeys (PowerShell)

## Estrategia de comunicacion Addon ↔ Companion

### Problema
Los addons de WoW Classic Era no pueden hacer HTTP requests, escribir archivos arbitrarios, ni usar sockets. La unica persistencia disponible son las SavedVariables, que WoW solo escribe a disco al recargar interfaz (`/reload`) o al salir.

El chat log incorporado (`/chatlog` → `Logs/WoWChatLog.txt`) no escribe mensajes en Classic Era, por lo que no es una fuente confiable.

### Solucion actual
**Inyeccion directa via teclas simuladas (SendKeys):**
1. El addon captura el mensaje entrante via `CHAT_MSG_*` y lo guarda en `ChatLingoDB.pending` (en memoria)
2. Cuando el usuario hace `/reload`, WoW persiste `ChatLingoDB` a disco como SavedVariable
3. El companion lee el archivo SavedVariable, traduce los pendientes, y escribe los resultados
4. El companion inyecta la traduccion en vivo usando PowerShell SendKeys para simular:
   - Enter (abrir chat)
   - `/run ChatFrame1:AddMessage("|cff00ccff[TR]|r traduccion", 1, 1, 0)`
   - Enter (ejecutar)
   - Escape (cerrar chat)
5. El addon tambien verifica `ChatLingoDB.results` en su ciclo `OnUpdate` y muestra traducciones pendientes

### Limitaciones
- SendKeys requiere la ventana de WoW activa/visible
- El flujo inicial requiere un `/reload` para que el companion vea los primeros pendientes
- La velocidad de escritura puede no ser suficiente para chats muy activos

### Ideas para futuro (no implementadas)
- **Console injection:** Usar `PostMessage` de Win32 API para enviar teclas a WoW incluso en background
- **Lua inline injection:** Que el companion use la consola de desarrollador de WoW (si esta habilitada) para ejecutar Lua directamente sin abrir el chat
- **Named pipe / socket local:** Si en el futuro el API de addons lo permite
- **OCR del chat frame:** Usar Windows UI Automation para leer el texto del chat y traducirlo externamente
- **Addon HTTP bridge:** Usar un proxy local que el addon consulta via mecanismos internos de WoW

## Que funciona
- [x] Addon carga sin errores en WoW Classic Era 1.15.8
- [x] Slash command `/cl` abre/cierra frame de configuracion
- [x] Frame de config con dropdown de idioma, checkboxes de canales, slider de polling, botones Limpiar/Reset/Cerrar
- [x] Companion traduce texto via Google Translate API
- [x] Companion inyecta traduccion al chat de WoW via keystrokes (SendKeys)
- [x] Debug interno via `ChatLingoDB.debug[]` (array en SavedVariables)
- [x] Repo Git publico en GitHub

## Que falta / Problemas conocidos
- [ ] `/chatlog` no escribe mensajes en Classic Era — el companion no puede confiar en el chat log
- [ ] **Flujo inicial torpe:** se necesita un `/reload` para que el companion vea los pendientes por primera vez
- [ ] **Filtrado por canal:** El companion traduce todo. El addon tiene config de canales pero el companion no la respeta
- [ ] **Cache de traducciones:** No hay cache persistente entre sesiones
- [ ] **Companion fragil:** SendKeys requiere la ventana de WoW activa/visible
- [ ] **No discrimina mensajes propios:** El companion traduce incluso los mensajes que escribe el usuario
- [ ] `CHAT_MSG_TRADE` no existe en Vanilla (era TBC+). Se maneja con `pcall`

## Instalacion

1. Copiar `ChatLingo/` a `_classic_era_\Interface\AddOns\`
2. Activar el addon en el menu de addons de WoW
3. Ejecutar el companion: `python companion/translator.py`
4. Para configurar, usar `/cl` en WoW
5. Opcional: escribir un mensaje en chat y luego `/reload` para que el companion procese los primeros pendientes

## Dependencias

- Python 3 con `requests`
- WoW Classic Era
