OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
test-scon : TestScon.scad
	$(OPENSCAD) -o TestScon.stl TestScon.scad
