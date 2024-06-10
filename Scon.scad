//
// Scon is a Json-like subset of openscad
//
//    Scon :== undef | boolean | number | string
//           [ Scon, Scon, Scon, ... ] | // list in json
//           [ [string,Scon], [String,Scon], ... ] // map in json
//
// scon_value allows for easy access to structured scon values via
// a path and an optional computed missing value lambda function.
//
// Ex: scon_value([["x",1],["y",0]],["x"]) == 1
//
// An optional third parameter can provide a path-dependent missing
// parameter function (which always produces undef by default).
//
// Ex:  scon_value([["x",1],["y",0]],["z"]) == undef
// But: scon_value([["x",1],["y",0]],["z"],function(path) 0) == 0
//
// See scon_make to make a wrapper function that simplifies using scon_value.
//
function scon_value(scon,path,missing = function(path) undef,dist = 0) =
  is_undef(path) ? missing :
  (len(path) <= dist || is_undef(scon)) ?
    (is_undef(scon) ? missing(path) : scon) :
    let (
      key = path[dist],
      next = is_undef(key) ?
        scon :
	is_string(key) ?
          _scon_map(scon, key, path) :
          _scon_index(scon, key, path)
    ) scon_value(next, path, missing, dist + 1);

//
// Make a scon wrapper to access scon data conveniently.
//
// Ex 1:
//  def_cfg = scon_make([["x",0],["y",0],["fn":100]);
//    def_cfg(["x"]) == 0;
//    def_cfg(["y"]) == 0;
//    def_cfg(["z"]) == undef;
//    def_cfg(["fn"]) == 100;
//
// Make allows for an optional second parameter of a previously
// made configuration as a fallback for missing values:
//
// Ex 2:
//  cfg = scon_make([["x",10],["z",3]],def_cfg);
//    cfg(["x"]) == 10
//    cfg(["y"]) == 0 // falls back to def_cfg
//    cfg(["z"]) == 3
//    cfg(["t"]) == undef
//    cfg(["t"],0) == 0 // cfg allows for missing value substitutions
//
//    
function scon_make(scon,base=undef)=
  is_undef(base) ?
    function(path,missing=undef)
      scon_value(scon,path,function (missing_path) missing)
  :
    function(path,missing=undef)
      scon_value(scon,path,function (missing_path) base(missing_path,missing));

//
// Convert a scon value to a json string
//
// Ex: scon_to_json(true) == "true"
//     scon_to_json(17) == "17"
//     scon_to_json("length") == "\"length\""
//     scon_to_json([["x",1],["y",2]]) == "{\"x\":1,\"y\":2}"
//     scon_to_json([2,3,5,8]) == "[2,3,5,8]"
//
//  List/object ambiguity! Since OpenSCAD has no native map, there must be an
//  ambiguity in the conversion to the distinct [item[0],item[1],...] list
//  and the {"name0":value0,"name1":value1,..} object notation in JSON.
//
//  The rule Scon uses is:
//
//    If every element of a Vector is a [string,value] pair, then it is converted
//    to an object.  Otherwise it is a list.
//
//    So [], [["x",1],["y",2]], are maps and become "{}" and "{\"x\":1,\"y\":2}"
//    any other Vector is converted to a list.
//
function scon_to_json(scon) =
  is_undef(scon) ? "null" :
  is_bool(scon) ? str(scon) :
  is_num(scon) ? str(scon) :
  is_string(scon) ? _scon_json_str(scon) :
  _scon_is_map(scon) ? _scon_json_map(scon) :
  is_list(scon) ? _scon_json_list(scon) :
  _scon_json_str("??? ",scon," ???");

function _scon_map(scon_map, key, path) =
    let (result = search([key], scon_map,0)[0])
      len(result) > 0 ? scon_map[result[len(result)-1]][1] : undef;

function _scon_index(scon_list, index, path) =
    (is_list(scon_list) && 0 <= index && index < len(scon_list)) ? scon_list[index] : undef;

function _scon_is_mapping(scon) =
    is_list(scon) && len(scon) == 2 && is_string(scon[0]);

function _scon_all_seq(seq,begin,end) =
  begin >= end ? true : seq(begin) && _scon_all_seq(seq,begin+1,end);

function _scon_is_map(scon) =
    is_list(scon) &&
    _scon_all_seq(function(i) _scon_is_mapping(scon[i]),0,len(scon));


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
  
function _scon_json_chr(c) =
  (c == "\"") ? "\\\"" :
  (c == "\\") ? "\\\\" :
  (c == "/") ? "\\/" :
  (c == "\x08") ? "\\b" :
  (c == "\x0c") ? "\\f" :
  (c == "\n") ? "\\n" :
  (c == "\r") ? "\\r" :
  (c == "\x09") ? "\\t" :
  c;  

function _scon_json_str(scon) =
  let (seq=function (i) _scon_json_chr(scon[i]))
  str("\"",_scon_str_seq(seq,0,len(scon)),"\"");

function _scon_json_map(scon) =
  let(seq=function(i) str(_scon_json_str(scon[i][0]),":",scon_to_json(scon[i][1])))
  str("{",_scon_str_join_seq(seq,0,len(scon)),"}");

function _scon_json_list(scon) =
  let(seq=function(i) scon_to_json(scon[i]))
  str("[",_scon_str_join_seq(seq,0,len(scon)),"]");


// \x09 is tab in openscad string literals
function _scon_space(str,pos=0)=len(search(str[pos]," \x09\n\r")) != 0;

function _scon_ltrim(str,begin,end) = (begin >= end || ! _scon_space(str,begin)) ? begin : _scon_ltrim(str,begin+1,end);

function _scon_rtrim(str,begin,end) = (begin >= end || ! _scon_space(str,end-1)) ? end : _scon_rtrim(str,begin,end-1);

function _scon_substreq(str,begin,end,to) = 
  len(to) != end-begin ? false :
  _scon_substreq_rec(str,begin,end,to,pos=0);

function _scon_substreq_rec(str,begin,end,to,pos) = 
  (begin >= end) ? true :
  str[begin] != to[pos] ? false :
  _scon_substreq_rec(str,begin+1,end,to,pos+1);

function _scon_substr(str,begin,end) = 
  (begin == 0 && end == len(str)) ? str : 
  _scon_str_seq(function (i) str[i], begin, end);

function _scon_digit(str,radix) =
  let (c = ord(str),
       d = (ord("0") <= c && c <= ord("9")) ? c - ord("0") : 
           (ord("a") <= c && c <= ord("f")) ? c - ord("a")+ 10 : 
           (ord("A") <= c && c <= ord("F")) ? c - ord("A")+ 10 :
           radix
       )
  (d < radix) ? d :
  assert(false,str("\"",str,"\""," is not a valid radix hexadecimal digit"));

function _scon_hex(str,begin,end) =
  (end <= begin ) ? 0 : 
  let (v = pow(16,end-begin-1)*_scon_digit(str[begin],16))
  v + _scon_hex(str,begin+1,end);

function _scon_unescape(json,begin,end) = 
  json[begin+1] == "\"" && end == begin + 2 ? "\"" :
  json[begin+1] == "\\" && end == begin + 2 ? "\\" :
  json[begin+1] == "/"  && end == begin + 2 ? "/" :
  json[begin+1] == "b"  && end == begin + 2 ? "\x08" :
  json[begin+1] == "f"  && end == begin + 2 ? "\x0c" :
  json[begin+1] == "n"  && end == begin + 2 ? "\n" :
  json[begin+1] == "r"  && end == begin + 2 ? "\r" :
  json[begin+1] == "t"  && end == begin + 2 ? "\x09" :
  json[begin+1] == "u"  && end == begin + 6 ? chr(_scon_hex(json,begin+2,end)) :
  assert(false, str(_scon_substr(json,begin,end)," is not a valid json escape sequence"));

function _scon_strpos(json,begin,end,ch) =
  (begin >= end) ? end :
  json[begin] == ch ? begin :
  _scon_strpos(json,begin+1,end,ch);
  
function _scon_from_json_str(json,begin,end) =
  let (bs=_scon_strpos(json,begin,end,"\\"))
  (bs >= end) ? _scon_substr(json,begin,end) :
  let (es = (json[bs+1] == "u") ? 6 : 2)
  str(_scon_substr(json,begin,bs),
      _scon_unescape(json,bs,bs+es),
      _scon_from_json_str(json,bs+es,end));

function _scon_from_json_object(json,begin,end)=assert(false,"unsupported");
function _scon_from_json_list(json,begin,end)=assert(false,"unsupported");
function _scon_from_json_num(json,begin,end)=assert(false,"unsupported");

// incomplete feature - parse json to scon.
function scon_from_json(json, __begin = undef, __end = undef) =
  let (_begin = is_undef(__begin) ? 0 : __begin,
       _end = is_undef(__end) ? len(json) : __end)
  let (begin = _scon_ltrim(json,_begin,_end),
       end = _scon_rtrim(json,begin,_end))
  (begin >= end) ? assert(false, "the empty string is not valid json") :
  _scon_substreq(json,begin,end,"null") ? undef :
  _scon_substreq(json,begin,end,"true") ? true :
  _scon_substreq(json,begin,end,"false") ? false :
  (json[begin] == "{" && json[end-1] == "}") ? _scon_from_json_object(json,begin+1,end-1) :
  (json[begin] == "[" && json[end-1] == "]") ? _scon_from_json_list(json,begin+1,end-1) :
  (json[begin] == "\"" && end-begin >= 2 && json[end-1] == "\"") ? _scon_from_json_str(json,begin+1,end-1) :
  _scon_from_json_num(json,begin,end);
