function Node_DynaSurf_Out(_x, _y, _group = noone) : Node_PCX(_x, _y, _group) constructor {
	name = "Output";
	
	manual_deletable	 = false;
	destroy_when_upgroup = true;
	
	inputs[| 0] = nodeValue("Surface", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	
	inputs[| 1] = nodeValue("x", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	
	inputs[| 2] = nodeValue("y", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	
	inputs[| 3] = nodeValue("sx", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	
	inputs[| 4] = nodeValue("sy", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	
	inputs[| 5] = nodeValue("angle", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	
	inputs[| 6] = nodeValue("color", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	
	inputs[| 7] = nodeValue("alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.PCXnode, noone);
	 
	outputs[| 0] = nodeValue("PCX", self, JUNCTION_CONNECT.output, VALUE_TYPE.PCXnode, noone);
	
	input_display_list = [ 0, 
		["Transform", false], 1, 2, 3, 4, 5, 
		["Draw",      false], 6, 7, 
	];
	
	static update = function() {
		var _surf = inputs[| 0].getValue();
		var _x    = inputs[| 1].getValue();
		var _y    = inputs[| 2].getValue();
		var _sx   = inputs[| 3].getValue();
		var _sy   = inputs[| 4].getValue();
		var _ang  = inputs[| 5].getValue();
		var _clr  = inputs[| 6].getValue();
		var _alp  = inputs[| 7].getValue();
		
		outputs[| 0].setValue(new __funcTree("draw", [ _surf, _x, _y, _sx, _sy, _ang, _clr, _alp ]));
	}
}