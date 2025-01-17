function sliderRange(_min, _max, _step, _onModify) : widget() constructor {
	minn = _min;
	maxx = _max;
	stepSize = _step;
	
	spr = THEME.slider;
	onModify = _onModify;
	
	dragging = -1;
	drag_mx  = 0;
	drag_sx  = 0;
	
	tb_value_min = new textBox(TEXTBOX_INPUT.number, function(val) { return onModify(0, clamp(val, minn, maxx)); });
	tb_value_max = new textBox(TEXTBOX_INPUT.number, function(val) { return onModify(1, clamp(val, minn, maxx)); });
	
	tb_value_min.slidable = true;
	tb_value_max.slidable = true;
	
	static setSlideSpeed = function(speed) {
		tb_value_min.setSlidable(speed);
		tb_value_max.setSlidable(speed);
	}
	
	static setInteract = function(interactable = noone) { 
		self.interactable = interactable;
		tb_value_min.interactable = interactable;
		tb_value_max.interactable = interactable;
	}
	
	static register = function(parent = noone) {
		tb_value_min.register(parent);
		tb_value_max.register(parent);
	}
	
	static drawParam = function(params) {
		return draw(params.x, params.y, params.w, params.h, params.data, params.m);
	}
	
	static draw = function(_x, _y, _w, _h, _data, _m) {
		x = _x;
		y = _y;
		w = _w;
		h = _h;
		if(!is_real(_data[0])) return;
		if(!is_real(_data[1])) return;
		
		var tb_w = ui(64);
		var sw = _w - (tb_w + ui(16)) * 2;
		
		tb_value_min.setFocusHover(active, hover);
		tb_value_min.draw(_x, _y, tb_w, TEXTBOX_HEIGHT, _data[0], _m);
		
		tb_value_max.setFocusHover(active, hover);
		tb_value_max.draw(_x + _w - tb_w, _y, tb_w, TEXTBOX_HEIGHT, _data[1], _m);
		
		var _x0 = _x + tb_w + ui(16);
		draw_sprite_stretched(spr, 0, _x0, _y + _h / 2 - ui(4), sw, ui(8));	
		
		var _slider_x0 = _x0 + clamp((_data[0] - minn) / (maxx - minn), 0, 1) * sw;
		var _slider_x1 = _x0 + clamp((_data[1] - minn) / (maxx - minn), 0, 1) * sw;
		
		draw_sprite_stretched_ext(spr, 4, min(_slider_x0, _slider_x1), _y + _h / 2 - ui(4), abs(_slider_x1 - _slider_x0), ui(8), COLORS._main_accent, 1);	
		draw_sprite_stretched(spr, 1, _slider_x0 - ui(10), _y, ui(20), _h);
		draw_sprite_stretched(spr, 1, _slider_x1 - ui(10), _y, ui(20), _h);
		
		if(dragging > -1) {
			if(dragging == 0)
				draw_sprite_stretched_ext(spr, 3, _slider_x0 - ui(10), _y, ui(20), _h, COLORS._main_accent, 1);
			else if(dragging == 1)
				draw_sprite_stretched_ext(spr, 3, _slider_x1 - ui(10), _y, ui(20), _h, COLORS._main_accent, 1);
			
			var val = (_m[0] - _x0) / sw * (maxx - minn) + minn;
			val = round(val / stepSize) * stepSize;
			val = clamp(val, minn, maxx);
			if(key_mod_press(CTRL))
				val = round(val);
			
			if(onModify(dragging, val))
				UNDO_HOLDING = true;
			
			if(mouse_release(mb_left)) {
				UNDO_HOLDING = false;
				dragging = -1;
			}
		} else if(hover) {
			var _hover = -1;
				
			if(point_in_rectangle(_m[0], _m[1], _slider_x0 - ui(10), _y, _slider_x0 + ui(10), _y + _h)) {
				draw_sprite_stretched(spr, 2, _slider_x0 - ui(10), _y, ui(20), _h);
				_hover = 0;
			}
			if(point_in_rectangle(_m[0], _m[1], _slider_x1 - ui(10), _y, _slider_x1 + ui(10), _y + _h)) {
				draw_sprite_stretched(spr, 2, _slider_x1 - ui(10), _y, ui(20), _h);
				_hover = 1;
			}
				
			if(_hover > -1 && mouse_press(mb_left, active)) {
				dragging = _hover;
				drag_mx  = _m[0];
				drag_sx  = _data[_hover];
			}
		}
		
		resetFocus();
		
		return h;
	}
}