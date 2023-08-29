function Panel_Linear_Setting() : PanelContent() constructor {
	title = __txtx("preview_3d_settings", "3D Preview Settings");
	
	w = ui(380);
	
	bg_y = -1;
	
	properties = []
	static setHeight = function() { h = ui(12 + 36 * array_length(properties)); }
	
	static drawSettings = function(panel) {
		var yy = ui(24);
		var th = ui(36);
		var ww = ui(200);
		var wh = TEXTBOX_HEIGHT;
		
		var bg_y_to = bg_y;
		
		if(bg_y) draw_sprite_stretched_ext(THEME.ui_panel_bg, 0, ui(4), bg_y, w - ui(8), th, COLORS.panel_prop_bg, 0.5);
		
		for( var i = 0, n = array_length(properties); i < n; i++ ) {
			var _prop = properties[i];
		
			var _widg = _prop[0];
			var _text = _prop[1];
			var _data = _prop[2]();
		
			_widg.setFocusHover(pFOCUS, pHOVER);
			_widg.register();
			
			if(pHOVER && point_in_rectangle(mx, my, 0, yy - th / 2, w, yy + th / 2)) 
				bg_y_to = yy - th / 2;
				
			draw_set_text(f_p1, fa_left, fa_center, COLORS._main_text);
			draw_text_add(ui(16), yy, _text);
		
			var params = new widgetParam(w - ui(8) - ww, yy - wh / 2, ww, wh, _data,, [ mx, my ], x, y);
			if(is_instanceof(_widg, checkBox)) {
				params.halign = fa_center;
				params.valign = fa_center;
			}
			
			_widg.drawParam(params);
		
			yy += th;
		}
		
		if(bg_y == -1) bg_y = bg_y_to;
		else           bg_y = lerp_float(bg_y, bg_y_to, 3);
	}
	
	function drawContent(panel) { drawSettings(panel); }
}