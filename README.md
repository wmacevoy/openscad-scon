# SCON

JSON for OpenSCAD

## TL;DR.

```
include <Scon.scad>

cfg_scon = [
  ["fn",100],
  ["sphere",[
    ["radius",1],
    ["center",[1,2,3]],
  ]],
];

cfg=scon_make(cfg_scon);

fn = cfg(["fn"]);

sphere_center = cfg(["sphere","center"]);
sphere_radius = cfg(["sphere","radius"]);
sphere_fn = cfg(["sphere","fn"],fn); // missing value replacement

translate(sphere_center) sphere(sphere_radius,$fn=sphere_fn);
```

## Introduction

SCON is a convenient configuration data subset for OpenSCAD similar to JSON for Javascript.

A SCON value can be

* A number, a string, a boolean, or undef.
* A list of values.
* A map, which is a list of [string,value] pairs.

For example,
```
cfg_scon = [
  ["fn",100],
  ["arms",[
    ["left",[["color","blue"],["length",6]]],
    ["right",[["color","white"],["length",3]]],
  ]],
  ["sequence",[3,5,8]],
];
```

You can use these values via scon_value, as in
```
arms_left_length=scon_value(cfg_scon,["arms","left","length"]);
eight=scon_value(cfg_scon,["sequence",2]);
arms_cfg=scon_value(cfg_scon,["arms"]);
```

## Make

Better, you can wrap scon_value in a function so you don't have to write as much to use:
```
cfg = scon_make(cfg_scon);

arms_left_length=cfg(["arms","left","length"]);

// you can supply an optional replacement (default undef) for missing values...
arms_left_radius=cfg(["arms","left","radius"],missing=1);
```

# Make Make ...

Base configurations can be used to simplify describing similar structures, you have to
describe how they new configurations differ from the base configuration:

```
// arm is the base configuration
arm=scon_make([
  ["state","down"],
  ["length",10],
  ["radius",1],
]);

// left_arm is an arm, but with some changes & additions
left_arm=scon_make([
  ["state","up"],
],arm);

// right_arm is an arm, but with some changes & additions
right_arm=scon_make([
  ["length",8],
  ["tool",true],
],arm);
```
Both left and right arms will have the radius of 1, the left will be in the up state, and
the right arm will have a tool.  You can nest this idea as much as you find helpful.

## Me

Once you have a property function from make, then you can make pretty clean modules, like

```
module arm_draw(me) {
  let (length=me(["length"]), radius=me(["radius"]), tool=me(["tool"],false)) {
    // generate arm of length and radius, etc...
  }
}
arm_draw(left_arm);
arm_draw(right_arm);
```

## SCON→JSON

Since JSON is so universal, it is convenient to convert SCON to JSON:

 * `scon_to_json(true) == "true"`
 * `scon_to_json(17) == "17"`
 * `scon_to_json("length") == "\"length\""`
 * `scon_to_json([["x",1],["y",2]]) == "{\"x\":1,\"y\":2}"`
 * `scon_to_json([]) == "{}"`
 * `scon_to_json([2,3,5,8]) == "[2,3,5,8]"`

### List/object ambiguity

Since OpenSCAD has no native map, there must be an ambiguity in the conversion to the
distinct [item[0],item[1],...] list and the {"name0":value0,"name1":value1,..} object
notation in JSON.

The rule Scon uses is:
```
If every element of a list is a [string,value] pair, then it is converted
to a {"name":value,...} object.  Otherwise it is a [item,...] list.
```
In particular, an empty list is always converted to an object.

## JSON→SCON

`json2scon.py` is a python 3.7 script to convert to json to scon.
Basic usage is
```
python3 json2scon.py < input.json > output.scon
```

You can add a `--fmt='cfg=scon_make({scon});` or similar pattern if you want more than the raw scon in the output.

## cfg.json root configuration pattern

JSON is common configuration format.  Here is a nice pattern to take for a project where your tools incluide other languages so there is a single root document

1. Create a JSON configuration document for example (cfg.json):
```json
{
    "stick" : {
        "nz" : 360,
        "ntheta" : 360,
        "height" : 180.0,
        "radius" : 6.0,
        "innerDiameter" : 4.0,
        "starEnd" : true
    },
    "hole" : {
        "nz" : 360,
        "ntheta" : 360,
        "radius" : 1,
        "height" : 2
    }
}
```

2. Use python `python3 json2scon.py <cfg.json >cfg.scon` or [QuickJS](https://bellard.org/quickjs/) `qjs json2scon.qjs <cfg.json >cfg.scon` to translate JSON to SCON format.  You should not change `cfg.scon` except by automatically re-generating it probably in a build script along with the rest of your build tool chain.
```
[["fiddlestick", [["nz", 360], ["ntheta", 360], ...
```

3. Make a simple config file that reads the file (cfg.scad).
```
include <Scon.scad>;
cfg_scon=include <cfg.scon>;
cfg=scon_make(cfg_scon);
// print current configuration
echo(scon_to_json(cfg_scon));
```

4. Now, in your scad files you can include this file (stick.scad). This way you are not copying values into different places.  This is a big win.
```
include <cfg.scad>;
stick_nz = cfg(["stick","nz"]);
...
```
