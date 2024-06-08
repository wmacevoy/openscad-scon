include <Scon.scad>

assert(_scon_all_seq(function (i) false,0,0) == true );
assert(_scon_all_seq(function (i) true ,0,3) == true );
assert(_scon_all_seq(function (i) false,0,3) == false);
assert(_scon_all_seq(function (i) i != 0,0,3) == false);
assert(_scon_all_seq(function (i) i != 1,0,3) == false);
assert(_scon_all_seq(function (i) i != 2,0,3) == false);

assert(_scon_all_seq(function (i) i != 0,0,10) == false);

assert(_scon_is_map("hi") == false);
assert(_scon_is_map(3.14) == false);
assert(_scon_is_map(true) == false);
assert(_scon_is_map([1,2,3]) == false);
assert(_scon_is_map([]) == true);
assert(_scon_is_map([["a",1]]) == true);
assert(_scon_is_map([["a",1],["b",1]]) == true);
spath=function(path) str_join_list(path,0,len(path),sep="/");

assert(_scon_map([["alpha",1],["beta",2]],"alpha",["dir","subdir"]) == 1);
assert(_scon_map([["alpha",1],["beta",2]],"c",["a","b"]) == undef);
assert(_scon_index([2,3,5],1,["a","b"]) == 3);
assert(_scon_index([2,3,5],6,["a","b"]) == undef);

config_scon=[["x",1],["y",[["q","why"],["a",[true,false]]]]];
assert(scon_value(config_scon,["x"]) == 1);
assert(scon_value(config_scon,["y","q"]) == "why");
assert(scon_value(config_scon,["y","a",0]) == true);
assert(scon_value(config_scon,["y","a",0,undef]) == true);
assert(scon_value(config_scon,[undef,"y","a",0,undef]) == true);
assert(scon_value(config_scon,[undef,"y",undef,"a",undef,0,undef]) == true);

function config(p0=undef,p1=undef,p2=undef,p3=undef,p4=undef,p5=undef,p6=undef,p7=undef,p8=undef,p9=undef) =
  scon_value(config_scon,[p0,p1,p2,p3,p4,p5,p6,p7,p8,p9]);

assert(config("x") == 1);
assert(config("y","q") == "why");
assert(config("y","a",0) == true);

// override y/a config for submodule
subconfig_scon = [["y",[["a",[false,true]]]]];

function subconfig(p0=undef,p1=undef,p2=undef,p3=undef,p4=undef,p5=undef,p6=undef,p7=undef,p8=undef,p9=undef) =
  scon_value(subconfig_scon,[p0,p1,p2,p3,p4,p5,p6,p7,p8,p9],
     function (path) scon_value(config_scon,path));

assert(subconfig("x") == 1);
assert(subconfig("y","q") == "why");
assert(subconfig("y","a",0) == false);

made0 = scon_make([["x",0],["y",0]]);
assert(made0(["x"]) == 0);
assert(made0(["y"]) == 0);
assert(made0(["z"]) == undef);
assert(made0(["x"],7) == 0);
assert(made0(["y"],7) == 0);
assert(made0(["z"],7) == 7);

made1 = scon_make([["x",3]],made0);
assert(made1(["x"]) == 3);
assert(made1(["y"]) == 0);
assert(made1(["z"]) == undef);
assert(made1(["x"],7) == 3);
echo(made1(["y"],7));
assert(made1(["y"],7) == 0);
assert(made1(["z"],7) == 7);

assert(_scon_json_chr("a") == "a");
assert(_scon_json_chr("\"") == "\\\"");
assert(_scon_json_chr("\\") == "\\\\", _scon_json_chr("\\"));
assert(_scon_json_chr("/") == "\\/");
assert(_scon_json_chr("\x08") == "\\b");
assert(_scon_json_chr("\x0C") == "\\f");
assert(_scon_json_chr("\n") == "\\n");
assert(_scon_json_chr("\r") == "\\r");
assert(_scon_json_chr("\x09") == "\\t");

// raw string: \path/to "her's"
// scad encoded literal: "\\path/to \"her's\""
// json encoded literal: "\\path\/to \"her's\""
// scad encoded json literal: "\"\\\\path\\/to \\\"her's\\\"\""
assert(_scon_json_str("\\path/to \"her's\"") == "\"\\\\path\\/to \\\"her's\\\"\"");

assert(scon_to_json("hi") == "\"hi\"");
assert(scon_to_json(undef) == "null");
assert(scon_to_json(true) == "true");
assert(scon_to_json(false) == "false");
assert(scon_to_json(33.3) == "33.3");
assert(scon_to_json([1,2,3]) == "[1,2,3]");
assert(scon_to_json([["a",1],["b",2]]) == "{\"a\":1,\"b\":2}");

assert(_scon_substreq("test",0,0,"") == true);
assert(_scon_substreq("test",0,0,"x") == false);
assert(_scon_substreq("test",0,1,"t") == true);
assert(_scon_substreq("test",0,1,"ts") == false);
assert(_scon_substreq("test",0,1,"") == false);
assert(_scon_substreq("test",0,1,"s") == false);
assert(_scon_substreq("test",1,3,"es") == true);
assert(_scon_substreq("test",1,3,"tes") == false);
assert(_scon_substreq("test",1,3,"est") == false);

assert(_scon_substr("test",0,0) == "");
assert(_scon_substr("test",0,1) == "t");
assert(_scon_substr("test",1,3) == "es");
assert(_scon_substr("test",1,4) == "est");

assert(_scon_space(" test",0) == true);
assert(_scon_space(" test",1) == false);
assert(_scon_space(" \rtest",1) == true);
assert(_scon_space(" \ntest",1) == true);
assert(_scon_space(" \x09test",1) == true);

assert(_scon_ltrim("test",0,4) == 0);
assert(_scon_ltrim(" test",0,5) == 1);
assert(_scon_ltrim("  \n\r\x09test",0,3) == 3);


assert(_scon_rtrim("test",0,4) == 4);
assert(_scon_rtrim("test ",0,5) == 4);
assert(_scon_rtrim("test  \n\r\x09",6,9) == 6);

assert(scon_from_json("null") == undef);
assert(scon_from_json("true") == true);
assert(scon_from_json("false") == false);
assert(scon_from_json("\"test\"") == "test");

echo("\"\\\"\"");
echo(scon_from_json("\"\\\"\""));
assert(scon_from_json("\"\\\"\"") == "\"");
assert(scon_from_json("\"\\\\\"") == "\\");
assert(scon_from_json("\"\\/\"") == "/");
assert(scon_from_json("\"\\b\"") == "\x08");
assert(scon_from_json("\"\\f\"") == "\x0c");
assert(scon_from_json("\"\\n\"") == "\n");
assert(scon_from_json("\"\\r\"") == "\r");
assert(scon_from_json("\"\\t\"") == "\x09");
assert(scon_from_json("\"\\ufead\"") == "\uFEAD");

assert(scon_from_json("\"test 1\\ntest 2\\r\"") == "test 1\ntest 2\r");
assert(scon_from_json("\"test 1\\ttest 2\\r\"") == "hello\x09world\r");

echo("control","test scon ok");
