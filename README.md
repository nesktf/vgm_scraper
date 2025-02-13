# VGM Scraper
Extractor de la lista completa de Veteranos de Guerra de Malvinas, usando datos de
la página web de listado veteranos del [Ministerio de Defensa de Argentina](https://veteranos.defensa.gob.ar/)

La página web del ministerio de defensa toma el listado de los ~23.600 veteranos en una sola
request y los renderiza directamente en la página. Esto hace que la página sea bastante lenta
de manejar, y la hace inusable en dispositivos de gama baja (como smartphones)

Este software toma los datos y los formatea en JSON para ser manejados de una forma más cómoda
por un software externo

# Dependencias
- Lua5.1 ó LuaJIT + luarocks
- [Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3) 
- [lua-cjson](https://github.com/mpx/lua-cjson)

# Úso
```sh
$ (luajit/lua5.1) scraper.lua <archivo_json> [archivo_temporal]
$ cat <archivo_json> | jq | less
```

# Licencias
- Los datos extraidos desde la página del Ministerio de Defensa están licenciados bajo
[Creative Commons Atribución 4.0 Internacional](https://creativecommons.org/licenses/by/4.0/deed.es) 
- El código sigue la licencia establecida en el archivo
[LICENSE.md](./LICENSE.md) de este repositorio

# Notas
- El software esta hecho con el objetivo de ser útil para otros, no me responsabilizo por el 
posible mal úso de los datos extraidos.
- Los términos y condiciones estipulados por el gobierno Argentino se encuentran
[aquí](https://www.argentina.gob.ar/terminos-y-condiciones)
