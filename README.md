# SCON

JSON for OpenSCAD

## TL;DR.

```
include <scon.scad>

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

* Python: `python3 scon_from_json.py <cfg.json >cfg.scon`
* Node: `node scon_from_json.js <cfg.json >cfg.scon`
* [QuickJS](https://bellard.org/quickjs/) `qjs --std -m scon_from_json.js <cfg.json >cfg.scon`

You can add a `--fmt='cfg=scon_make({scon});` or similar pattern if you want more than the raw scon in the output.

If you have this as a common config file (cfg.scad):
```
include <scon.scad>;
cfg_scon=include <cfg.scon>;
cfg=scon_make(cfg_scon);
echo(scon_to_json(cfg_scon));
```
or, briefly
```
cfg=scon_make(include <cfg.scon>);
echo(scon_to_json(cfg([])));
```

Then all your parts files and build scripts can have access to the same configuration.

## JSON→SCON (Developer Build of OpenSCAD)

OpenSCAD has built-in support of JSON in the developer build without the composability
and exportability of SCON.  If JSON is a supported feature of your OpenSCAD, then you
can convert JSON to SCON with
```
include <scon.scad>;
cfg_json=import("cfg.json");
cfg_scon=scon_from_json(cfg_json);
cfg=scon_make(cfg_scon);
echo(scon_to_json(cfg_scon));
```
or, briefly
```
// only if your OpenSCAD supports direct JSON import
cfg=scon_make(scon_from_json(import("cfg.json")));
echo(scon_to_json(cfg([])));
```

# Test
If an object (cube) is created, then all the tests pass
```
openscad -o pass.stl tests/scon_test.scad
```
