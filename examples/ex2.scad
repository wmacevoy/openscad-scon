include <scon.scad>

sphere_scon = [
  ["radius",1],
  ["center",[1,2,3]],
  ["color",[1,1,0]],
  ["fn",32]
];

cube_scon = [
  ["size",1],
  ["center",[-1,-2,-3]],
  ["color",[0,0,1]],
];

cfg_scon = [
  ["sphere", sphere_scon],
  ["cube", cube_scon]
];

// makes a convenient accessor function
cfg = scon_make(cfg_scon);

sphere_radius=cfg(["sphere","radius"],1);
sphere_center=cfg(["sphere","center"],[0,0,0]);
sphere_color=cfg(["sphere","color"],[1,1,0]);
sphere_fn=cfg(["sphere","fn"],32);
color(sphere_color) translate(sphere_center) sphere(r=sphere_radius,$fn=sphere_fn);

cube_size=cfg(["cube","size"],[1,1,1]);
cube_center=cfg(["cube","center"],[0,0,0]);
cube_color=cfg(["cube","color"],[1,1,0]);
color(cube_color) translate(cube_center) cube(size=cube_size,center=true);
