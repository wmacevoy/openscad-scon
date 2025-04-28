include <scon.scad>

//
//     shape
//    /     \
//   cube    sphere
//  /       /      \
// cube1   sphere1  sphere2
//

// base configuration values for shapes
shape = scon_make([
  ["kind",undef],
  ["center",[0,0,0]],
  ["color",[1,1,0]],
  ["fn", 100],
]);

shape_make = function(scon) scon_make(scon,shape);

module shape_draw(me) {
  let (me_center=me(["center"]), me_color=me(["color"])) {
    color(me_color) translate(me_center) children();
  }
}

sphere = scon_make([
  ["kind","sphere"],
  ["radius",1],
], shape);

sphere_make = function(scon) scon_make(scon,sphere);

module sphere_draw(me) {
  let(me_radius = me(["radius"]), me_fn = me(["fn"]))
  {
     shape_draw(me) sphere(r=me_radius,$fn=me_fn);
  }
}

cube = scon_make([
  ["kind","cube"],
  ["size",[1,1,1]],
], shape);

cube_make = function(scon) scon_make(scon,cube);

module cube_draw(me) {
  let(me_size = me(["size"]), me_fn = me(["fn"])) {
    shape_draw(me) { cube(size=me_size, center = true); }
  }
}

module draw(me) {
  let(me_kind = me(["kind"])) {
    if (me_kind == "sphere") {
      sphere_draw(me);
    } else if (me_kind == "cube") {
      cube_draw(me);
    } else if (me_kind == "shapes") {
      shapes_draw(me);
    } else {
      assert(false,str("unknown kind: ",me_kind));
    }
  }
}

sphere1 = sphere_make([
  ["fn",12],
  ["center",[10,0,0]],
]);

sphere2 = sphere_make([
  ["radius",2],
  ["color",[1,0,0,0.25]],
]);

cube1 = cube_make([
  ["center",[4,0,0]],
  ["color",[0,0,1]],
]);

for (shape = [sphere1,sphere2,cube1]) {
  draw(shape);
}

