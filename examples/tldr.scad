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
