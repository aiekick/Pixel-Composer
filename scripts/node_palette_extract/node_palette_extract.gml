function Node_Palette_Extract(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Palette Extract";
	w = 96;
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1] = nodeValue("Max colors", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 5, "Amount of color in a palette.")
		.rejectArray();
	
	inputs[| 2] = nodeValue("Seed", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, irandom(99999), "Random seed to be used to initialize K-mean algorithm.")
		.rejectArray();
	
	inputs[| 3] = nodeValue("Algorithm", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, { data: [ "K-mean", "Frequency", "All colors" ], update_hover: false })
		.rejectArray();
	
	inputs[| 4] = nodeValue("Color Space", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1)
		.setDisplay(VALUE_DISPLAY.enum_scroll, { data: [ "RGB", "HSV" ], update_hover: false })
		.rejectArray();
	
	outputs[| 0] = nodeValue("Palette", self, JUNCTION_CONNECT.output, VALUE_TYPE.color, [ ])
		.setDisplay(VALUE_DISPLAY.palette);
	
	static getPreviewValues = function() { return getInputData(0); }
	
	input_display_list = [
		["Surfaces", true],	0,
		["Palette",	false],	3, 4, 1, 2,
	]
	
	current_palette = [];
	current_color = 0;
	
	attribute_surface_depth();
	
	function sortPalette(pal) { #region
		array_sort(pal, function(c0, c1) {
			var r0 = color_get_red(c0) / 255;
			var r1 = color_get_red(c1) / 255;
			var g0 = color_get_green(c0) / 255;
			var g1 = color_get_green(c1) / 255;
			var b0 = color_get_blue(c0) / 255;
			var b1 = color_get_blue(c1) / 255;
			
			var l0 = sqrt( .241 * r0 + .691 * g0 + .068 * b0 );
			var l1 = sqrt( .241 * r1 + .691 * g1 + .068 * b1 );
			
			if(abs(l0 - l1) > 0.05) return l0 > l1;
			
			var h0 = color_get_hue(c0) / 255;
			var h1 = color_get_hue(c1) / 255;
			
			if(abs(h0 - h1) > 0.05) return h0 > h1;
			
			var s0 = color_get_saturation(c0) / 255;
			var s1 = color_get_saturation(c1) / 255;
			
			var v0 = color_get_value(c0) / 255;
			var v1 = color_get_value(c1) / 255;
			
			return s0 * v0 > s1 * v1;
		})
	} #endregion
	
	function extractKmean(_surfFull, _size, _seed) { #region
		var _space = getInputData(4);
		var _surf  = surface_create_valid(min(32, surface_get_width_safe(_surfFull)), min(32, surface_get_height_safe(_surfFull)), attrDepth());
		_size = max(1, _size);
		
		var ww = surface_get_width_safe(_surf);
		var hh = surface_get_height_safe(_surf);
		
		surface_set_shader(_surf, noone);
			draw_surface_stretched_safe(_surfFull, 0, 0, ww, hh);
		surface_reset_shader();
		
		var c_buffer = buffer_create(ww * hh * 4, buffer_fixed, 2);
		var colors = [];
		
		buffer_get_surface(c_buffer, _surf, 0);
		buffer_seek(c_buffer, buffer_seek_start, 0);
		
		var _min = [ 1, 1, 1 ];
		var _max = [ 0, 0, 0 ];
		var a, b, c, col;
		
		for( var i = 0; i < ww * hh; i++ ) {
			b = buffer_read(c_buffer, buffer_u32);
			c = b & ~(0b11111111 << 24);
			a = b & (0b11111111 << 24);
			if(a == 0) continue;
			
			switch(_space) {
				case 0 : col = [ color_get_red(c) / 255, color_get_green(c) / 255,      color_get_blue(c) / 255, 0 ];  break;
				case 1 : col = [ color_get_hue(c) / 255, color_get_saturation(c) / 255, color_get_value(c) / 255, 0 ]; break;
				case 2 : col = [ color_get_hue(c) / 255, color_get_saturation(c) / 255, color_get_value(c) / 255, 0 ]; break;
			}
			
			array_push(colors, col);
			for( var j = 0; j < 3; j++ ) {
				_min[j] = min(_min[j], col[j]);
				_max[j] = max(_max[j], col[j]);
			}
		}
			
		buffer_delete(c_buffer);
		
		var cnt = [];
		random_set_seed(_seed);
		for( var i = 0; i < _size; i++ )
			cnt[i] = [ random(1), random(1), random(1), 0 ];
			
		repeat(8) {
			var _cnt = [];
			for( var i = 0; i < _size; i++ ) {
				_cnt[i][0] = cnt[i][0];
				_cnt[i][1] = cnt[i][1];
				_cnt[i][2] = cnt[i][2];
			}
			
			for( var i = 0, n = array_length(colors); i < n; i++ ) {
				var ind = 0;
				var dist = 999;
				var _cl = colors[i];
				
				for( var j = 0; j < _size; j++ ) {
					var _cn = cnt[j];
					var d = point_distance_3d(_cl[0], _cl[1], _cl[2], _cn[0], _cn[1], _cn[2]);
					if(d < dist) {
						dist = d;
						ind = j;
					}
				}
				
				colors[i][3] = ind;
			}
			
			for( var i = 0; i < _size; i++ )
				cnt[i] = [ 0, 0, 0, 0 ];
				
			for( var i = 0, n = array_length(colors); i < n; i++ ) {
				var _cl = colors[i];
				cnt[_cl[3]][0] += _cl[0];
				cnt[_cl[3]][1] += _cl[1];
				cnt[_cl[3]][2] += _cl[2];
				cnt[_cl[3]][3]++;
			}
			
			for( var i = 0; i < _size; i++ ) {
				cnt[i][0] = cnt[i][3]? cnt[i][0] / cnt[i][3] : 0;
				cnt[i][1] = cnt[i][3]? cnt[i][1] / cnt[i][3] : 0;
				cnt[i][2] = cnt[i][3]? cnt[i][2] / cnt[i][3] : 0;
			}
			
			var del = 0;
			for( var i = 0; i < _size; i++ ) {
				del = max(del, point_distance_3d(cnt[i][0], cnt[i][1], cnt[i][2], _cnt[i][0], _cnt[i][1], _cnt[i][2]));
			}
			
			if(del < 0.001) break;
		}
		
		var palette = [];
		var clr; 
		
		for( var i = 0; i < _size; i++ ) {
			var closet = 0;
			var dist = 999;
			var _cl = cnt[i];
			
			for( var j = 0; j < array_length(colors); j++ ) {
				var _cn = colors[j];
				var d = point_distance_3d(_cl[0], _cl[1], _cl[2], _cn[0], _cn[1], _cn[2]);
				
				if(d < dist) {
					dist = d;
					closet = j;
				}
			}
			
			switch(_space) {
				case 0 : clr = make_color_rgb(colors[closet][0] * 255, colors[closet][1] * 255, colors[closet][2] * 255); break;
				case 1 : clr = make_color_hsv(colors[closet][0] * 255, colors[closet][1] * 255, colors[closet][2] * 255); break;
				case 2 : clr = make_color_hsv(colors[closet][0] * 255, colors[closet][1] * 255, colors[closet][2] * 255); break;
			}
			
			array_push_unique(palette, clr);
		}
		
		surface_free(_surf);
		sortPalette(palette);
		
		return palette;
	} #endregion
	
	function extractAll(_surfFull) { #region
		var ww = surface_get_width_safe(_surfFull);
		var hh = surface_get_height_safe(_surfFull);
		
		var c_buffer = buffer_create(ww * hh * 4, buffer_fixed, 2);
		
		buffer_get_surface(c_buffer, _surfFull, 0);
		buffer_seek(c_buffer, buffer_seek_start, 0);
		
		var palette = [];
		
		for( var i = 0; i < ww * hh; i++ ) {
			var b = buffer_read(c_buffer, buffer_u32);
			var c = b & ~(0b11111111 << 24);
			var a = b & (0b11111111 << 24);
			if(a == 0) continue;
			c = make_color_rgb(color_get_red(c), color_get_green(c), color_get_blue(c));
			if(!array_exists(palette, c)) 
				array_push(palette, c);
		}
		
		buffer_delete(c_buffer);
		return palette;
	} #endregion
	
	function extractFrequence(_surfFull, _size) { #region
		var msize = 128;
		var _surf = surface_create_valid(min(msize, surface_get_width_safe(_surfFull)), min(msize, surface_get_height_safe(_surfFull)));
		_size = max(1, _size);
		
		var ww = surface_get_width_safe(_surf);
		var hh = surface_get_height_safe(_surf);
		
		surface_set_target(_surf);
		DRAW_CLEAR
		BLEND_OVERRIDE;
		draw_surface_stretched_safe(_surfFull, 0, 0, ww, hh);
		BLEND_NORMAL;
		surface_reset_target();
		
		var c_buffer = buffer_create(ww * hh * 4, buffer_fixed, 2);
		var colors   = array_create(ww * hh);
		
		buffer_get_surface(c_buffer, _surf, 0);
		buffer_seek(c_buffer, buffer_seek_start, 0);
		
		var palette = [];
		
		var clrs = ds_map_create();
		for( var i = 0; i < ww * hh; i++ ) {
			var b = buffer_read(c_buffer, buffer_u32);
			var c = b & ~(0b11111111 << 24);
			var a = b & (0b11111111 << 24);
			if(a == 0) continue;
			c = make_color_rgb(color_get_red(c), color_get_green(c), color_get_blue(c));
			if(ds_map_exists(clrs, c)) 
				clrs[? c]++;
			else
				clrs[? c] = 0;
		}
			
		buffer_delete(c_buffer);
		
		var pr = ds_priority_create();
		var amo = ds_map_size(clrs);
		var k = ds_map_find_first(clrs);
		
		repeat(amo) {
			ds_priority_add(pr, k, clrs[? k]);
			k = ds_map_find_next(clrs, k);
		}
		
		for( var i = 0; i < _size; i++ ) {
			if(ds_priority_empty(pr)) break;
			array_push(palette, ds_priority_delete_max(pr));
		}
			
		ds_priority_destroy(pr);
		ds_map_destroy(clrs);
		return palette;
	} #endregion
	
	static step = function() { #region
		var _algo = getInputData(3);
		
		inputs[| 1].setVisible(_algo != 2);
		inputs[| 2].setVisible(_algo == 0);
		inputs[| 4].setVisible(_algo == 0);
	} #endregion
	
	static extractPalette = function(_surf, _algo, _size, _seed) { #region
		if(!is_surface(_surf)) return [];
		
		switch(_algo) {
			case 0 : return extractKmean(_surf, _size, _seed);
			case 1 : return extractFrequence(_surf, _size);
			case 2 : return extractAll(_surf);
		}
		
		return [];
	} #endregion
	
	static extractPalettes = function() { #region
		var _surf = getInputData(0);
		var _size = getInputData(1);
		var _seed = getInputData(2);
		var _algo = getInputData(3);
		var res = [];
		
		if(is_surface(_surf)) {
			res = extractPalette(_surf, _algo, _size, _seed);
		} else if(is_array(_surf)) {
			res = array_create(array_length(_surf));
			for( var i = 0, n = array_length(_surf); i < n; i++ )
				res[i] = extractPalette(_surf[i], _algo, _size, _seed);
		}
		
		outputs[| 0].setValue(res);
	} #endregion
	
	static onInspector1Update = function() { extractPalettes(); triggerRender(); }
	static onValueUpdate	  = function() { extractPalettes(); }
	static onValueFromUpdate  = function() { extractPalettes(); }
	
	static update = function() { extractPalettes(); }
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		var bbox = drawGetBbox(xx, yy, _s);
		if(bbox.h < 1) return;
		
		drawPalette(outputs[| 0].getValue(), bbox.x0, bbox.y0, bbox.w, bbox.h);
	} #endregion
}