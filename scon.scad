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

// Make a property-extractor function from an SCON value.
// Basic usage:
//
//   cfg_scon = [["x",1],["y",true]];
//   cfg = scon_make([["x",1],["y",true]]);
//   x=cfg(["x"]);
//   y=cfg(["y"]);
//   z=cfg(["z"], 3); // z = 3 because it is not in cfg_scon.
//
// Advanced Meta-programming note:
//   - cfg([])   ⇒ returns the full SCON data structure.
//   - cfg(undef)⇒ returns the configured missing-fallback function.
// This allows for introspection of the data used to make cfg function.
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

//
// Development builds of OpenSCAD with the import-function feature enabled
// can import Json directly.  To convert this import to SCON, you can use this
// function.
//
// The json2scon.js and json2scon.py scripts create a back-portable way to
// do this by externally converting to 
// 
// Developer Build usage:
//
//   cfg = scon_make(json_to_scon(import("config.json")));
//
// Portable usage:
//
//   # from terminal or build script
//   python3 json2scon.py <config.json >config.scon
//   # or
//   node json2scon.js <config.json >config.scon
//   # or (quickjs)
//   qjs --std -m json2scon.js <config.json >config.scon
//
//   # in OpenSCAD
//   cfg = scon_make(include "config.scon");
//
function scon_from_json(json) =
  is_object(json)
    ? [ for (k = json) [ k, scon_from_json(json[k]) ] ]
  : is_list(json)
    ? [ for (i = [0:len(json)-1]) scon_from_json(json[i]) ]
  : json;

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
  _scon_str_seq(seq,begin,end);

// sep can also be a lambda function of the index
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
