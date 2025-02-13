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

print("Requesting data...")
assert(do_request(temp_file))

print("Parsing data...")
local raw = assert(read_file(temp_file))
  :match("<tbody>(.*)</tbody>")
  :gsub("(%s+)<","\n")
  :gsub("\n/tr>%s+", "")
  :gsub("[<+]?[/+]?(t)[r|d](>)","")

local enums = {
  [0] = "DNI",
  [1] = "Nombre",
  [2] = "Fuerza",
  [3] = "Grado",
  [4] = "Condicion",
  [5] = "Vive?",
}

local i = 0
local list = {}
local curr

local count = 1
for line in raw:gmatch("[^\n]+") do
  if (i == 0) then
    curr = {}
    curr[enums[i]] = unescape(line)
    i = i + 1
  elseif (i == 5) then
    i = 0
    table.insert(list, curr)
    print(string.format("Parsing VGM %d", count))
    count = count + 1
  else
    curr[enums[i]] = unescape(line)
    i = i + 1
  end
end

assert(write_json(out_file, list))
print("Done!")
