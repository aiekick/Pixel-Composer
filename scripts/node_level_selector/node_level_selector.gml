function Node_Level_Selector(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Level Selector";
	
	shader = sh_level_selector;
	uniform_middle = shader_get_uniform(shader, "middle");
	uniform_range  = shader_get_uniform(shader, "range");
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1] = nodeValue("Mid point", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 2] = nodeValue("Range",   self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 3] = nodeValue("Mask", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 4] = nodeValue("Mix", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 5] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		active_index = 5;
	
	inputs[| 6] = nodeValue("Channel", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0b1111)
		.setDisplay(VALUE_DISPLAY.toggle, { data: array_create(4, THEME.inspector_channel) });
	
	__init_mask_modifier(3); // inputs 7, 8, 
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	attribute_surface_depth();
	
	level_renderer = new Inspector_Custom_Renderer(function(_x, _y, _w, _m, _hover, _focus) { #region
		var _h = 128;
		var x0 = _x;
		var x1 = _x + _w;
		var y0 = _y;
		var y1 = _y + _h; 
		level_renderer.h = 128;
		
		var _middle = getInputData(1);
		var _span   = getInputData(2);
		var _min    = _middle - _span;
		var _max    = _middle + _span;
		
		draw_set_color(COLORS.node_level_shade);
		draw_rectangle(x0, y0, x0 + max(0, _min) * _w, y1, false);
		draw_rectangle(x0 + min(1, _max) * _w, y0, x1, y1, false);
		
		for( var i = 0; i < 4; i++ ) {
			var _bx = x1 - 20 - i * 24;
			var _by = y0;
			
			if(buttonInstant(THEME.button_hide, _bx, _by, 20, 20, _m, _focus, _hover) == 2) 
				histShow[i] = !histShow[i];
			draw_sprite_ui_uniform(THEME.circle, 0, _bx + 10, _by + 10, 1, COLORS.histogram[i], 0.5 + histShow[i] * 0.5);
		}
		
		if(histMax > 0)
			histogramDraw(x0, y1, _w, _h);

		draw_set_color(COLORS.node_level_outline);
		draw_rectangle(x0, y0, x1, y1, true);
		
		return _h;
	}); #endregion
	
	input_display_list = [ 5, 6, 
		level_renderer,
		["Surfaces", true],	0, 3, 4, 7, 8, 
		["Level",	false],	1, 2,
	];
	histogramInit();
	
	static onInspect = function() { #region
		if(array_length(current_data) > 0)
			histogramUpdate(current_data[0]);
	} #endregion
	
	static onValueFromUpdate = function(index) { #region
		if(index == 0) {
			update();
			if(array_length(current_data) > 0)
				histogramUpdate(current_data[0]);
		}
	} #endregion
	
	static step = function() { #region
		__step_mask_modifier();
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) { #region
		var _middle = _data[1];
		var _range  = _data[2];
		
		surface_set_target(_outSurf);
			DRAW_CLEAR
			BLEND_OVERRIDE;
			
			shader_set(shader);
			shader_set_uniform_f(uniform_middle, _middle);
			shader_set_uniform_f(uniform_range , _range );
			
			draw_surface_safe(_data[0], 0, 0);
			shader_reset();
			
			BLEND_NORMAL;
		surface_reset_target();
		
		__process_mask_modifier(_data);
		_outSurf = mask_apply(_data[0], _outSurf, _data[3], _data[4]);
		_outSurf = channel_apply(_data[0], _outSurf, _data[6]);
		
		return _outSurf;
	} #endregion
}