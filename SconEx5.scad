include <Scon.scad>

//
//     shape---------------
//    /     \              \
//   cube    sphere         shapes
//  /       /      \              \
// cube1   sphere1  sphere2        all(sphere1,sphere2,cube1)
//

// base configuration values for shapes
shape = scon_make([
  ["kind",undef],
  ["center",[0,0,0]],
  ["color","children"],
  ["fn", 100],
]);

shape_make = function(scon) scon_make(scon,shape);

module shape_color(me) {
  let (me_color=me(["color"])) {
    if (is_undef(me_color) || me_color == "children") {
      children();
    } else {
      color(me_color) children();
    }
  }
}

module shape_draw(me) {
  let (me_center=me(["center"])) {
    shape_color(me) translate(me_center) children();
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

shapes = shape_make([
 ["kind","shapes"],
 ["color","children"],
 ["children",[]],
],shape);

shapes_make = function(scon) scon_make(scon,shapes);

module shapes_draw(me) {
  let(me_children = me(["children"])) {
    shape_draw(me) {
      for (child = me_children) {
        draw(child);
      }
    }
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

all = shapes_make([
  ["children",[sphere1,sphere2,cube1]],
]);

draw(all);

