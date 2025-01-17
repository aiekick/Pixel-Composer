function Node_Perlin_Extra(_x, _y, _group = noone) : Node_Shader_Generator(_x, _y, _group) constructor {
	name   = "Extra Perlins";
	shader = sh_perlin_extra;
	
	inputs[| 1] = nodeValue("Position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getDimension(index); });
		addShaderProp(SHADER_UNIFORM.float, "position");
		
	inputs[| 2] = nodeValue("Scale", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 4, 4 ])
		.setDisplay(VALUE_DISPLAY.vector);
		addShaderProp(SHADER_UNIFORM.float, "scale");
	
	inputs[| 3] = nodeValue("Iteration", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 2);
		addShaderProp(SHADER_UNIFORM.integer, "iteration");
	
	inputs[| 4] = nodeValue("Tile", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true, "Tiling only works with integer scale, and some effect type doesn't support tiling.");
		addShaderProp(SHADER_UNIFORM.integer, "tile");
			
	inputs[| 5] = nodeValue("Seed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, irandom(99999));
		addShaderProp(SHADER_UNIFORM.float, "seed");
		
	inputs[| 6] = nodeValue("Color mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_button, [ "Greyscale", "RGB", "HSV" ]);
		addShaderProp(SHADER_UNIFORM.integer, "colored");
	
	inputs[| 7] = nodeValue("Color R range", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 1 ])
		.setDisplay(VALUE_DISPLAY.slider_range);
		addShaderProp(SHADER_UNIFORM.float, "colorRanR");
	
	inputs[| 8] = nodeValue("Color G range", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 1 ])
		.setDisplay(VALUE_DISPLAY.slider_range);
		addShaderProp(SHADER_UNIFORM.float, "colorRanG");
	
	inputs[| 9] = nodeValue("Color B range", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 1 ])
		.setDisplay(VALUE_DISPLAY.slider_range);
		addShaderProp(SHADER_UNIFORM.float, "colorRanB");
	
	inputs[| 10] = nodeValue("Noise type", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Absolute worley", "Fluid", "Noisy", "Camo", "Blocky", "Max", "Vine" ]);
		addShaderProp(SHADER_UNIFORM.integer, "type");
		
	inputs[| 11] = nodeValue("Parameter A", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0)
		.setDisplay(VALUE_DISPLAY.slider);
		addShaderProp(SHADER_UNIFORM.float, "paramA");
		
	inputs[| 12] = nodeValue("Parameter B", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1);
		addShaderProp(SHADER_UNIFORM.float, "paramB");
		
	input_display_list = [
		["Output", 	 true],	0, 5, 
		["Noise",	false],	10, 1, 2, 3, 4, 11, 12, 
		["Render",	false], 6, 7, 8, 9, 
	];
	
	static step = function() { #region
		var _col = getInputData(6);
		var _typ = getInputData(10);
		
		inputs[| 7].setVisible(_col != 0);
		inputs[| 8].setVisible(_col != 0);
		inputs[| 9].setVisible(_col != 0);
		
		inputs[| 7].name = _col == 1? "Color R range" : "Color H range";
		inputs[| 8].name = _col == 1? "Color G range" : "Color S range";
		inputs[| 9].name = _col == 1? "Color B range" : "Color V range";
		
		inputs[| 11].setVisible(_typ > 0);
		inputs[| 12].setVisible(false);
	} #endregion
}