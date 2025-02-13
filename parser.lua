local coroutine = require("coroutine")
local curl = require("cURL")
local json = require("cjson")

local out_file = "./out.json"
local temp_file = "./temp.html"

local function do_request(path)
  local file = io.open(path, "w+")
  if (not file) then
    return nil, "Cant' open file"
  end
  curl.easy{
      url = 'https://veteranos.defensa.gob.ar/index.php',
      writefunction = file,
      httpheader = {
        "Host: veteranos.defensa.gob.ar",
        "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0",
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      }
    }
    :perform()
    :close()
  file:close()

  return true
end

local function read_file(path)
  local f = io.open(path, "rb")
  if (not f) then
    return nil, "Can't open file"
  end
  local content = f:read("*all")
  f:close()
  return content
end

local function grep_table(str)
  local status, out = pcall(function()
    return str
      :match("<tbody>(.*)</tbody>")
      :gsub("(%s+)<","\n")
      :gsub("\n/tr>%s+", "")
      :gsub("[<+]?[/+]?(t)[r|d](>)","")
  end)
  return status and out or nil, out
end

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
  str = string.gsub( str, '&acute;', '´')
  str = string.gsub( str, '&Ntilde;', 'Ñ')
  str = string.gsub( str, '&ntilde;', 'ñ')
  str = string.gsub( str, '&Aacute;', 'Á')
  str = string.gsub( str, '&Eacute;', 'É')
  str = string.gsub( str, '&Iacute;', 'Í')
  str = string.gsub( str, '&Oacute;', 'Ó')
  str = string.gsub( str, '&Uacute;', 'Ú')
  str = string.gsub( str, '&Uuml;', 'Ü')
  str = string.gsub( str, '&aacute;', 'á')
  str = string.gsub( str, '&eacute;', 'é')
  str = string.gsub( str, '&iacute;', 'í')
  str = string.gsub( str, '&oacute;', 'ó')
  str = string.gsub( str, '&uacute;', 'ú')
  str = string.gsub( str, '&uuml;', 'ü')
  str = string.gsub( str, '&yacute;', 'ý')
  str = string.gsub( str, '&Auml;', 'Ä')
  str = string.gsub( str, '&Euml;', 'Ë')
  str = string.gsub( str, '&Iuml;', 'Ï')
  str = string.gsub( str, '&Ouml;', 'Ö')
  str = string.gsub( str, '&Uuml;', 'Ü')
  str = string.gsub( str, '&Yacute;', 'Ý')
  str = string.gsub( str, '&auml;', 'ä')
  str = string.gsub( str, '&euml;', 'ë')
  str = string.gsub( str, '&iuml;', 'ï')
  str = string.gsub( str, '&ouml;', 'ö')
  str = string.gsub( str, '&uuml;', 'ü')
  str = string.gsub( str, '&#(%d+);', function(n) return string.char(n) end )
  str = string.gsub( str, '&#x(%d+);', function(n) return string.char(tonumber(n,16)) end )
  str = string.gsub( str, '&amp;', '&' ) -- Be sure to do this after all others
  return str
end
--
print("Requesting data...")
assert(do_request(temp_file))

print("Parsing data...")

local raw, err = grep_table(read_file(temp_file))
if (not raw) then
  print("Failed to parse content: "..err)
  os.exit(1)
end

local list = {}
local parser = coroutine.create(function(first)
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

    curr.vive = (line == "SI")
    table.insert(list, curr)
    line = coroutine.yield()
  end
end)

for line in raw:gmatch("[^\n]+") do
  coroutine.resume(parser, line)
end

-- print(inspect(list))
assert(write_json(out_file, list))
print(string.format("Parsed %d VGMs!", #list))
