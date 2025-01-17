function Node_PB_Draw_Trapezoid(_x, _y, _group = noone) : Node_PB_Draw(_x, _y, _group) constructor {
	name = "Trapezoid";
	
	inputs[| 3] = nodeValue("Axis", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0 )
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Horizontal", "Vertical" ]);
	
	inputs[| 4] = nodeValue("Type", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0 )
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Symmetric", "Independent" ]);
	
	inputs[| 5] = nodeValue("Bevel", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.5 )
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 6] = nodeValue("Bevel 1", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.5 )
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 7] = nodeValue("Bevel 2", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.5 )
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 8] = nodeValue("Invert", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false );
	
	input_display_list = [
		["Draw",	false], 0, 1, 2, 
		["Shape",	false], 3, 4, 8, 5, 6, 7, 
	];
	
	static step = function() {
		var _type = current_data[4];
		
		inputs[| 5].setVisible(_type == 0);
		inputs[| 6].setVisible(_type == 1);
		inputs[| 7].setVisible(_type == 1);
	}
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var _pbox = _data[0];
		var _fcol = _data[1];
		var _mask = _data[2];
		var _axis = _data[3];
		var _type = _data[4];
		var _bev  = _data[5];
		var _bev1 = _data[6];
		var _bev2 = _data[7];
		var _invt = _data[8];
		
		if(_pbox == noone) return _pbox;
		
		var _nbox = _pbox.clone();
		_nbox.content = surface_verify(_nbox.content, _pbox.w, _pbox.h);
		
		var p0x = 0,	   p0y = 0;
		var p1x = _pbox.w, p1y = 0;
		var p2x = 0,	   p2y = _pbox.h;
		var p3x = _pbox.w, p3y = _pbox.h;
		
		if(_type == 0) {
			if(_axis == 0) {
				var w = _pbox.w - (_pbox.w * _bev) / 2;
				
				if(_invt ^^ _pbox.mirror_v) {
					p2x += w;
					p3x -= w;
				} else {
					p0x += w;
					p1x -= w;
				}
			} else {
				var h = _pbox.h - (_pbox.h * _bev) / 2;
				
				if(_invt ^^ _pbox.mirror_h) {
					p1x += h;
					p3x -= h;
				} else {
					p0y += h;
					p2y -= h;
				}
			}
		} else if(_type == 1) {
			if(_axis == 0) {
				var w1 = _pbox.w - (_pbox.w * _bev1) / 2;
				var w2 = _pbox.w - (_pbox.w * _bev2) / 2;
				
				if(_pbox.mirror_h) {
					var t = w1;
					w1 = w2;
					w2 = t;
				}
				
				if(_invt ^^ _pbox.mirror_v) {
					p2x += w1;
					p3x -= w2;
				} else {
					p0x += w1;
					p1x -= w2;
				}
			} else {
				var h1 = _pbox.h - (_pbox.h * _bev1) / 2;
				var h2 = _pbox.h - (_pbox.h * _bev2) / 2;
				
				if(_pbox.mirror_v) {
					var t = h1;
					h1 = h2;
					h2 = t;
				}
				
				if(_invt ^^ _pbox.mirror_h) {
					p1x += h1;
					p3x -= h2;
				} else {
					p0y += h1;
					p2y -= h2;
				}
			}
		}
		
		surface_set_target(_nbox.content);
			DRAW_CLEAR
			
			draw_set_color(_fcol);
			draw_primitive_begin(pr_trianglelist);
				draw_vertex(p0x, p0y);
				draw_vertex(p1x, p1y);
				draw_vertex(p2x, p2y);
				
				draw_vertex(p0x, p0y);
				draw_vertex(p2x, p2y);
				draw_vertex(p3x, p3y);
			draw_primitive_end();
			
			PB_DRAW_APPLY_MASK
		surface_reset_target();
		
		PB_DRAW_CREATE_MASK
		
		return _nbox;
	}
}