tests/test_scon.stl : tests/test_scon.scad scon.scad
	$(OPENSCAD) -o tests/test_scon.stl tests/test_scon.scad
