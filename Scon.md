# SCON - SCAD Object Notation (JSON for SCAD)

Scon is a data subset of OpenSCAD comparable to the JSON subset of Javascript.
It is convenient configuration data subset for OpenSCAD.

## Scon value can be

* A number, a string, a boolean, or undef.
* A list of SCON values.
* A map (list) of [string,SCON value] pairs.

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

You can use these values via scon_value...
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

If you want to report some configuration information to other places, there is a an scon_to_json for that purpose.

Because OpenSCAD does not support the idea of a dictionary/map/key-value pair natively, there is 