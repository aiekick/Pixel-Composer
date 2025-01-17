function Node_create_Blend(_x, _y, _group = noone, _param = {}) {
	var node = new Node_Blend(_x, _y, _group);
	return node;
}

function Node_Blend(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Blend";
	atlas_index  = 1;
	manage_atlas = false;
	
	inputs[| 0] = nodeValue("Background", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, noone);
	inputs[| 1] = nodeValue("Foreground", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, noone);
	
	inputs[| 2] = nodeValue("Blend mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, BLEND_TYPES );
	
	inputs[| 3] = nodeValue("Opacity", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 4] = nodeValue("Mask", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 5] = nodeValue("Fill mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "None", "Stretch", "Tile" ]);
	
	inputs[| 6] = nodeValue("Output dimension", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Background", "Forground", "Mask", "Maximum", "Constant" ])
		.rejectArray();
	
	inputs[| 7] = nodeValue("Constant dimension", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, DEF_SURF)
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 8] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		active_index = 8;
		
	inputs[| 9] = nodeValue("Preserve alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false);
		
	inputs[| 10] = nodeValue("Horizontal Align", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_button, [ THEME.inspector_surface_halign, THEME.inspector_surface_halign, THEME.inspector_surface_halign]);
		
	inputs[| 11] = nodeValue("Vertical Align", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_button, [ THEME.inspector_surface_valign, THEME.inspector_surface_valign, THEME.inspector_surface_valign]);
	
	inputs[| 12] = nodeValue("Invert mask", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false);
	
	inputs[| 13] = nodeValue("Mask feather", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider, { range: [1, 16, 1] });
		
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	input_display_list = [ 8, 
		["Surfaces",	 true],	0, 1, 4, 12, 13, 6, 7,
		["Blend",		false], 2, 3, 9,
		["Transform",	false], 5, 10, 11, 
	]
	
	attribute_surface_depth();
	
	temp_surface	   = [ surface_create(1, 1), surface_create(1, 1) ];
	blend_temp_surface = temp_surface[1];
	
	static step = function() { #region
		var _back = getSingleValue(0);
		var _fore = getSingleValue(1);
		var _fill = getSingleValue(5);
		var _outp = getSingleValue(6);
		
		var _atlas  = is_instanceof(_fore, SurfaceAtlas);
		
		inputs[| 5].setVisible(!_atlas);
		inputs[| 6].editWidget.data_list = _atlas? [ "Background", "Forground" ] : [ "Background", "Forground", "Mask", "Maximum", "Constant" ];
		inputs[| 7].setVisible(_outp == 4);
		
		inputs[| 10].setVisible(_fill == 0 && !_atlas);
		inputs[| 11].setVisible(_fill == 0 && !_atlas);
		
		var _msk = is_surface(getSingleValue(4));
		inputs[| 12].setVisible(_msk);
		inputs[| 12].setVisible(_msk);
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) { #region
		var _back	 = _data[0];
		var _fore	 = _data[1];
		var _type	 = _data[2];
		var _opacity = _data[3];
		var _mask	 = _data[4];
		var _fill	 = _data[5];
		
		var _outp	 = _data[6];
		var _out_dim = _data[7];
		var _pre_alp = _data[9];
		
		var _halign = _data[10];
		var _valign = _data[11];
		
		var _mskInv = _data[12];
		var _mskFea = _data[13];
		
		var cDep    = attrDepth();
		
		var ww = 1, hh  = 1;
		var _backDraw   = _back;
		var _foreDraw   = _fore;
		
		var _atlas  = is_instanceof(_fore, SurfaceAtlas);
		
		switch(_outp) { // Dimension
			case 0 :
				ww = surface_get_width_safe(_back);
				hh = surface_get_height_safe(_back);
				break;
			case 1 :
				ww = surface_get_width_safe(_fore);
				hh = surface_get_height_safe(_fore);
				break;
			case 2 :
				ww = surface_get_width_safe(_mask);
				hh = surface_get_height_safe(_mask);
				break;
			case 3 :
				ww = max(surface_get_width_safe(_back),  surface_get_width_safe(_fore),  surface_get_width_safe(_mask));
				hh = max(surface_get_height_safe(_back), surface_get_height_safe(_fore), surface_get_height_safe(_mask));
				break;
			case 4 :
				ww = _out_dim[0];
				hh = _out_dim[1];
				break;
		}
		
		if(_fill == 0 || _atlas) { // Direct placement
			for( var i = 0; i < 2; i++ )
				temp_surface[i] = surface_verify(temp_surface[i], ww, hh, cDep);
			
			_foreDraw = temp_surface[1];
				
			if(_atlas) {
				if(_outp == 0) {
					surface_set_shader(_foreDraw, noone,, BLEND.over);
						draw_surface_safe(_fore.getSurface(), _fore.x, _fore.y);
					surface_reset_shader();
				} else if(_outp == 1) {
					_backDraw = temp_surface[0];
					
					surface_set_shader(_foreDraw, noone,, BLEND.over);
						draw_surface_safe(_fore, 0, 0);
					surface_reset_shader();
					
					surface_set_shader(_backDraw, noone,, BLEND.over);
						draw_surface_safe(_back, -_fore.x, -_fore.y);
					surface_reset_shader();
				}
			} else if(is_surface(_fore)) {
				var sx = 0;
				var sy = 0;
			
				var fw = surface_get_width_safe(_fore);
				var fh = surface_get_height_safe(_fore);
			
				switch(_halign) {
					case 0 : sx = 0; break;
					case 1 : sx = ww / 2 - fw / 2; break;
					case 2 : sx = ww - fw; break;
				}
			
				switch(_valign) {
					case 0 : sy = 0; break;
					case 1 : sy = hh / 2 - fh / 2; break;
					case 2 : sy = hh - fh; break;
				}
			
				surface_set_shader(_foreDraw, noone,, BLEND.over);
					draw_surface_safe(_fore, sx, sy);
				surface_reset_shader();
			}
		}
		
		var _output = noone;
		
		if(is_instanceof(_outSurf, SurfaceAtlas)) 
			_output = surface_verify(_outSurf.surface.surface, ww, hh, cDep);
		else	  
			_output = surface_verify(_outSurf, ww, hh, cDep);
		
		_mask = mask_modify(_mask, _mskInv, _mskFea);
		
		surface_set_shader(_output, noone);
			draw_surface_blend(_backDraw, _foreDraw, _type, _opacity, _pre_alp, _mask, _fill == 2);
		surface_reset_shader();
		
		if(_atlas) {
			var _newAtl = _fore.clone();
			
			if(_outp == 0) {
				_newAtl.x = 0;
				_newAtl.y = 0;
			}
			
			_newAtl.setSurface(_output);
			return _newAtl;
		}
		
		return _outSurf;
	} #endregion
}