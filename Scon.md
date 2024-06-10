# SCON - SCAD Object Notation (JSON for SCAD)

## TL;DR

```
cfg_scon = [
  ["fn",100],
  ["sphere",[
    ["radius",1],
    ["center",[1,2,3]],
  ]],
];

cfg=make(cfg_scon);

fn = cfg(["fn"]);

sphere_center = cfg(["sphere","center"]);
sphere_radius = cfg(["sphere","radius"]);
sphere_fn = cfg(["sphere","fn"],fn); // missing value replacement

translate(sphere_center) sphere(sphere_radius,$fn=sphere_fn);
```

## Intro

Scon is a data subset of OpenSCAD comparable to the JSON subset of Javascript.
It is convenient configuration data subset for OpenSCAD.

## Scon value can be

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

Better, you can wrap scon_value in a function so you don't have to write as much to look up a value:
```
cfg = scon_make(cfg_scon);

arms_left_length=cfg(["arms","left","length"]);

// you can supply a value value for missing parameters...
arms_left_radius=cfg(["arms","left","radius"],missing=1);
```

# Make Make ...

If there is a similarity, you can setup a basic configuration and only override and extend them, instead of repeating yourself.

```
arm=scon_make([
  ["state","down"],
  ["length",10],
  ["radius",1],
]);

left_arm=scon_make([
  ["state","up"],
],arm);

right_arm=scon_make([
  ["tool",...],
],arm);
```
Both left and right arms will have the length of an arm, the left will be in the up state, and the right arm will have tool properties.  You can nest this idea as much as you find helpful.

## Me

Once you have a property function from make, then you can make pretty clean modules, like

```
arm=scon_make([
  ["state","down"],
  ["length",10],
  ["radius",1],
]);

left_arm=scon_make([
  ["state","up"],
],arm);

right_arm=scon_make([
  ["tool",...],
],arm);

module arm_draw(me) {
  let (length=me(["length"],1), color=me(["color"])) {
    // generate arm of length and color, etc...
  }
}
arm_draw(left_arm);
arm_draw(right_arm);
```

## JSON

Convert a scon value to a json string

``
scon_to_json(true) == "true";
scon_to_json(17) == "17";
scon_to_json("length") == "\"length\"";
scon_to_json([["x",1],["y",2]]) == "{\"x\":1,\"y\":2}";
scon_to_json([]) == "{}";
scon_to_json([2,3,5,8]) == "[2,3,5,8]";
```

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
