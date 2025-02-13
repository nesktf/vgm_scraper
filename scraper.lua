local coroutine = require("coroutine")
local curl = require("cURL")
local json = require("cjson")

local function write_json(path, content)
  local f = io.open(path, "w+")
  if (not f) then
    return nil, "Can't open file"
  end
  f:write(json.encode(content))
  f:close()
  return true
end

local function unescape(str)
  str = string.gsub(str, '&acute;', '´')
  str = string.gsub(str, '&Ntilde;', 'Ñ')
  str = string.gsub(str, '&ntilde;', 'ñ')
  str = string.gsub(str, '&Aacute;', 'Á')
  str = string.gsub(str, '&Eacute;', 'É')
  str = string.gsub(str, '&Iacute;', 'Í')
  str = string.gsub(str, '&Oacute;', 'Ó')
  str = string.gsub(str, '&Uacute;', 'Ú')
  str = string.gsub(str, '&Uuml;', 'Ü')
  str = string.gsub(str, '&aacute;', 'á')
  str = string.gsub(str, '&eacute;', 'é')
  str = string.gsub(str, '&iacute;', 'í')
  str = string.gsub(str, '&oacute;', 'ó')
  str = string.gsub(str, '&uacute;', 'ú')
  str = string.gsub(str, '&uuml;', 'ü')
  str = string.gsub(str, '&yacute;', 'ý')
  str = string.gsub(str, '&Auml;', 'Ä')
  str = string.gsub(str, '&Euml;', 'Ë')
  str = string.gsub(str, '&Iuml;', 'Ï')
  str = string.gsub(str, '&Ouml;', 'Ö')
  str = string.gsub(str, '&Uuml;', 'Ü')
  str = string.gsub(str, '&Yacute;', 'Ý')
  str = string.gsub(str, '&auml;', 'ä')
  str = string.gsub(str, '&euml;', 'ë')
  str = string.gsub(str, '&iuml;', 'ï')
  str = string.gsub(str, '&ouml;', 'ö')
  str = string.gsub(str, '&uuml;', 'ü')
  str = string.gsub(str, '&#(%d+);', function(n) return string.char(n) end )
  str = string.gsub(str, '&#x(%d+);', function(n) return string.char(tonumber(n,16)) end )
  str = string.gsub(str, '&amp;', '&' ) -- Be sure to do this after all others
  return str
end

local function make_parser(temp_path, gen, list)
  assert(gen == 'H' or gen == 'M')
  local path = string.format("%s_%s", temp_path, gen)
  local file = io.open(path, "w+")
  if (not file) then
    return nil, "Cant' open temp file"
  end
  print(string.format("Writing request to \"%s\"", path))

  local form = curl.form()
    :add_content("incluir", "1")
    :add_content("O", "2")
    :add_content("bgenero_vgm", gen == 'H' and "1" or "2")
  curl.easy()
    :setopt_url('https://veteranos.defensa.gob.ar/index.php')
    :setopt_writefunction(file)
    :setopt_httppost(form)
    :setopt_httpheader({
      "Host: veteranos.defensa.gob.ar",
      "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0",
      "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    })
    :perform()
  :close()
  file:close()

  return path, function(first)
    local line = first
    while (true) do
      local curr = {}
      curr.dni = line
      line = coroutine.yield()

      local names = line:gmatch("[^,]+")
      curr.apellido = unescape(names())
      curr.nombre = unescape(names()):sub(2)
      line = coroutine.yield()

      curr.fuerza = unescape(line)
      line = coroutine.yield()

      curr.grado = unescape(line)
      line = coroutine.yield()

      curr.condicion = unescape(line)
      line = coroutine.yield()

      curr.vive = unescape(line)
      curr.genero = gen
      table.insert(list, curr)
      line = coroutine.yield()
    end
  end
end

local function parse_data(temp_path, fun)
  if (not temp_path) then
    return nil, fun
  end

  local file = io.open(temp_path, "rb")
  if (not file) then
    return nil, "Can't open file"
  end
  local content = file:read("*all")
  file:close()

  local status, parsed = pcall(function()
    return content:match("<tbody>(.*)</tbody>")
      :gsub("(%s+)<","\n")
      :gsub("\n/tr>%s+", "")
      :gsub("[<+]?[/+]?(t)[r|d](>)","")
  end)
  if (not status) then
    return nil, string.format("Failed to parse HTML content: %s", tostring(parsed))
  end

  local parser = coroutine.create(fun)
  for line in parsed:gmatch("[^\n]+") do
    coroutine.resume(parser, line)
  end
end

do
  if (not arg[1]) then
    print("No out file specified")
    os.exit(1)
  end
  local out_file = arg[1]
  local temp_file = arg[2] or "/tmp/vgm_temp"

  local list = {}
  print("Parsing men data...")
  parse_data(make_parser(temp_file, 'H', list))

  print("Parsing women data...")
  parse_data(make_parser(temp_file, 'M', list))

  assert(write_json(out_file, list))
  print(string.format("Parsed %d VGMs!", #list))
end
