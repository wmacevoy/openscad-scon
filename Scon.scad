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

function scon_make(scon,base=undef)=
  is_undef(base) ?
    function(path,missing=undef)
      scon_value(scon,path,function (missing_path) missing)
  :
    function(path,missing=undef)
      scon_value(scon,path,function (missing_path) base(missing_path,missing));

function scon_to_json(scon) =
  is_undef(scon) ? "null" :
  is_bool(scon) ? str(scon) :
  is_num(scon) ? str(scon) :
  is_string(scon) ? _scon_json_str(scon) :
  _scon_is_map(scon) ? _scon_json_map(scon) :
  is_list(scon) ? _scon_json_list(scon) :
  _scon_json_str("??? ",scon," ???");

function scon_from_json(json, __begin = undef, __end = undef) =
  let (_begin = is_undef(__begin) ? 0 : __begin,
       _end = is_undef(__end) ? len(json) : __end)
  let (begin = _scon_ltrim(json,_begin,_end),
       end = _scon_rtrim(json,begin,_end))
  let ([scon,___begin] = _scon_from_json(json,begin,end))
  assert(___begin == end,str("invalid text after json ",_scon_substr(json,___begin,end));

function _scon_from_json(json, begin, end) =
  let (json_object = _scon_from_json_object(json,begin,end)) !is_undef(json_object) ? json_object :
  let (json_list = _scon_from_json_list(json,begin,end)) !is_undef(json_list) ? json_list : 
  let (json_null = _scon_from_json_word(json,begin,end,"null")) !is_undef(json_null) ? json_null :
  let (json_true = _scon_from_json_word(json,begin,end,"true")) !is_undef(json_true) ? json_true :
  let (json_false = _scon_from_json_word(json,begin,end,"false")) !is_undef(json_false) ? json_false :
  let (json_string = _scon_from_json_string(json,begin,end)) !is_undef(json_string) ? json_string :
  let (json_number = _scon_from_json_number(json,begin,end)) !is_undef(json_number) ? json_number :
  [undef,begin];

function _scon_from_json_word(json,begin,end,word,value) = 
  (end >= begin+len(word)) && _json_substreq(json,begin,begin+len(word),word) ? [value,begin+len(word] : undef;

function _scon_from_json_object(json,begin,end) =
  (end <= begin + 2 || json[begin] != "{") ? undef : assert(false, "unsupported");

function _scon_from_json_list(json,begin,end) =
  (end <= begin + 2 || json[begin] != "[") ? undef : assert(false, "unsupported");

function _scon_from_json_string(json,begin,end) =
  (end <= begin + 2 || json[begin] != "\"") ? undef : assert(false, "unsupported");

// only signed decimal numbers
function _scon_from_json_number(json,_begin,end) =
  let (
    sign = (end - _begin >= 2 && json[_begin] == "-") ? -1 : 1;
    begin = (sign == -1) ? _begin + 1 : begin
  )
  (end <= begin + 1) ? undef :
  let (c = ord(json[begin])-ord("0"))
  !(c >= 0 && c <= 9) ? undef :
  _scon_from_json_unsigned_number(sign,json,begin,end);

function _scon_from_json_unsigned_number(sign,json,begin,end,v=0) =
  let (c = begin < end ? ord(json[begin])-ord("0") : -1)
  !(c >= 0 && c <= 9) ? [sign*v,begin] :
  _scon_from_json_unsigned_number(sign,json,begin+1,end,10*v+c);

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

function _scon_json_unsigned_decimal(json,begin,end,k=0,v=0)=
  (end <= begin) ? assert(false,str("invalid unsigned decimal ",_scon_substr(json,begin,end))) :
  let (d=_scon_digit(json[begin],10))

function _scon_json_decimals(json,begin,end)=
  !(ord("0") <= ord(json[begin]) && ord(json[begin] <= ord("9")) ? 0 :
  1 + _scon_json_decimals(json,begin+1,end);

function _scon_decimal(str,begin,end) =
  (end <= begin ) ? 0 : 
  let (v = pow(10,end-begin-1)*_scon_digit(str[begin],10))
  v + _scon_decimal(str,begin+1,end);

function _scon_json_unsigned_decimal(json,begin,_end)=
  let (end = _scon_json_decimals(json,begin,_end))
  assert(begin < end,str("invalid unsigned decimal ",_scon_substr(json,begin,end))) &&
  [end,sign,_scon_decimal(json,begin,end)];

function _scon_json_signed_decimal(json,_begin,_end)=
  let (sign = (_begin < _end) && json[_begin] == '-' ? -1 : 1,
       begin = (_begin < _end) && (json[_begin] == '+' || json[_begin] == '-') ? _begin + 1 : _begin,
       end = _scon_json_decimals(json,begin,_end))
  assert(begin < end,str("invalid signed decimal ",_scon_substr(json,_begin,_end))) &&
  [end,sign,_scon_decimal(json,begin,end)];
      
       

function _scon_from_json_num(json,begin,end)=
  let (esv0 = _scon_json_signed_decimal(json,begin,end),
       
  (end > begin && json[begin] == '-') ? -
  assert(false,"unsupported");

function _scon_from_json_object(json,begin,end)=assert(false,"unsupported");
function _scon_from_json_list(json,begin,end)=
assert(false,"unsupported");
