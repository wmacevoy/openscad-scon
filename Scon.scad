function scon_value(data,path,default = function(path) undef,dist = 0) =
  (len(path) <= dist || is_undef(data)) ?
    (is_undef(data) ? default(path) : data) :
    let (
      key = path[dist],
      next = is_undef(key) ?
        data :
	is_string(key) ?
          _scon_map(data, key, path) :
          _scon_index(data, key, path)
    ) scon_value(next, path, default, dist + 1);

function _scon_map(map, key, path) =
    let (result = search([key], map,0)[0])
      len(result) > 0 ? map[result[len(result)-1]][1] : undef;

function _scon_index(list, index, path) =
    (is_list(list) && 0 <= index && index < len(list)) ? list[index] : undef;

function _scon_is_mapping(data) =
    is_list(data) && len(data) == 2 && is_string(data[0]);


function _scon_all_seq(seq,begin,end) =
  begin >= end ? true : seq(begin) && _scon_all_seq(seq,begin+1,end);

function _scon_is_map(data) =
    is_list(data) &&
    _scon_all_seq(function(i) _scon_is_mapping(data[i]),0,len(data));

scon_make = function(scon,base=undef)
  is_undef(base) ?
    function(path,missing=undef)
      scon_value(scon,path,function (missing_path) missing)
  :
    function(path,missing=undef)
      scon_value(scon,path,function (missing_path) base(missing_path,missing));


function _scon_str_seq(seq,begin,end) = // str(seq(begin),...,seq(end-1))
  let (n = (begin < end) ? end - begin : 0,
       m = ((n % 2) == 0) ? n/2 : (n-1) / 2)
  n > 1 ? str(_scon_str_seq(seq,begin,begin+m),_scon_str_seq(seq,begin+m,end)) :
  n == 1 ? str(seq(begin)) : "";

function _scon_str_list(list,begin=0,_end=undef) =
  let (seq = function (i) list[i],end = is_undef(_end) ? len(list) : _end)
  str_seq(seq,begin,end);

// sep can also be a lamba function of the index
function _scon_str_join_seq(seq,begin,end,sep=",") =
  let (n = (begin < end) ? end - begin : 0,
       m = ((n % 2) == 0) ? n/2 : (n-1) / 2)
  n > 1 ? str(_scon_str_join_seq(seq,begin,begin+m,sep),is_function(sep) ? sep(begin+m-1) : sep,_scon_str_join_seq(seq,begin+m,end,sep)) :
  n == 1 ? str(seq(begin)) : "";

function _scon_str_join_list(list,begin=0,_end=undef,sep=",") =
  let (seq = function (i) list[i],end = is_undef(_end) ? len(list) : _end)
  _scon_str_join_seq(seq,begin,end,sep);

function _scon_idigit(number,radix,position) =
  floor(number / pow(radix,position)) % radix;

function _scon_sdigit(number,radix,position) =
  let (digit = _scon_idigit(number,radix,position))
  (digit < 10 ? chr(ord("0")+digit) : chr(ord("a")-10+digit));

function _scon_hex(number,digits) = 
  _scon_str_seq(function(i) _scon_sdigit(number,16,digits-1-i),0,digits);
  
function _scon_json_chr(c) =
  (c == "\"") ? "\\\"" :
  (c == "\'") ? "\\\'" :
  (c == "\n") ? "\\n" :
  (c == "\r") ? "\\r" :
  (c == "\t") ? "\\t" :
  (ord(c) >= 32 && ord(c) <= 127) ? c :
  (ord(c) < 128) ? str("\\x",_scon_hex(ord(c),2)) :
  (ord(c) < 65536) ? str("\\u",_scon_hex(ord(c),4)) :
  str("\\U",_scon_hex(ord(c),6));
  
function _scon_json_str(scon) =
  let (seq=function (i) _scon_json_chr(scon[i]))
  str("\"",_scon_str_seq(seq,0,len(scon)),"\"");

function _scon_json_map(scon) =
  let(seq=function(i) str(_scon_json_str(scon[i][0]),":",scon_json(scon[i][1])))
  str("{",_scon_str_join_seq(seq,0,len(scon)),"}");

function _scon_json_list(scon) =
  let(seq=function(i) scon_json(scon[i]))
  str("[",_scon_str_join_seq(seq,0,len(scon)),"]");

function scon_json(scon) =
  is_undef(scon) ? "null" :
  is_bool(scon) ? str(scon) :
  is_num(scon) ? str(scon) :
  is_string(scon) ? _scon_json_str(scon) :
  _scon_is_map(scon) ? _scon_json_map(scon) :
  is_list(scon) ? _scon_json_list(scon) :
  _scon_json_str("??? ",scon," ???");
  


