include <Scon.scad>

// base configuration values for shapes
shape = scon_make([
  ["center",[0,0,0]],
  ["color",[1,1,0]],
  ["fn", 32]
]);

sphere1 = scon_make([
  ["radius",1]
], shape);

sphere2 = scon_make([
  ["radius",2],
  ["color",[1,0,0,0.25]],
], shape);

cube1 = scon_make([
  ["size",[1,1,1]],
  ["center",[-1,-2,-3]],
  ["color",[0,0,1]]
], shape);

// common steps for shapes
module shape_draw(me) {
  let (me_center=me(["center"]), me_color=me(["color"])) {
    color(me_color) translate(me_center) children();
  }
}

module sphere_draw(me) {
  let(me_radius = me(["radius"]), me_fn = me(["fn"]))
  {
    shape_draw(me) { sphere(r=me_radius,$fn=me_fn); }
  }
}

module cube_draw(me) {
  let(me_size = me(["size"]), me_fn = me(["fn"])) {
    shape_draw(me) { cube(size=me_size, center = true); }
  }
}

sphere_draw(sphere1);
sphere_draw(sphere2);
cube_draw(cube1);
