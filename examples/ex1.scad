include <scon.scad>

cfg_scon = [["fn", 100],["radius",10],["center",[1,2,3]]];

fn=scon_value(cfg_scon,["fn"]);
radius=scon_value(cfg_scon,["radius"]);
center=scon_value(cfg_scon,["center"]);

translate(center) sphere(r=radius,$fn=fn);


