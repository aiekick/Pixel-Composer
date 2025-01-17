function Panel_Graph_Export_Image(targetPanel) : PanelContent() constructor {
	title = __txtx("panel_export_graph", "Export Graph");
	w = ui(360);
	h = ui(524);
	min_h = h;
	
	self.targetPanel = targetPanel;
	
	nodeList = targetPanel.nodes_list;
	surface  = noone;
	settings = {
		scale		: 1,
		padding		: 64,
		
		bgEnable	: false,
		bgColor		: COLORS.panel_bg_clear,
		
		gridEnable  : false,
		gridColor   : targetPanel.project.graphGrid.color,
		gridAlpha   : targetPanel.project.graphGrid.opacity,
		
		borderPad	: 0,
		borderColor	: c_white,
		borderAlpha	: 0.05,
	};
	
	sel = 0;
	nodes_select = [ "All nodes", "Selected" ];
	widgets = [];
	widgets[0] = [ "Nodes",				new scrollBox(nodes_select, function(val) { sel = val; nodeList = val? ds_list_create_from_array(targetPanel.nodes_selecting) : targetPanel.nodes_list; refresh(); }, false),
		function() { return nodes_select[sel] }  ];
	widgets[1] = [ "Scale",				new textBox(TEXTBOX_INPUT.number, function(val) { settings.scale = val; refresh(); }),
		function() { return settings.scale }	];
	widgets[2] = [ "Padding",			new textBox(TEXTBOX_INPUT.number, function(val) { settings.padding = val; refresh(); }),
		function() { return settings.padding }	];
	widgets[3] = [ "Solid Background",	new checkBox(function() { settings.bgEnable = !settings.bgEnable; refresh(); }),
		function() { return settings.bgEnable }	];
	widgets[4] = [ "Background Color",	new buttonColor(function(val) { settings.bgColor = val; refresh(); }),
		function() { return settings.bgColor }	];
	widgets[5] = [ "Render Grid",		new checkBox(function() { settings.gridEnable = !settings.gridEnable; refresh(); }),
		function() { return settings.gridEnable }	];
	widgets[6] = [ "Grid Color",		new buttonColor(function(val) { settings.gridColor = val; refresh(); }),
		function() { return settings.gridColor }	];
	widgets[7] = [ "Grid Opacity",		new textBox(TEXTBOX_INPUT.number, function(val) { settings.gridAlpha = val; refresh(); }),
		function() { return settings.gridAlpha }	];
	widgets[8] = [ "Border",			new textBox(TEXTBOX_INPUT.number, function(val) { settings.borderPad = val; refresh(); }),
		function() { return settings.borderPad }	];
	widgets[9] = [ "Border Color",		new buttonColor(function(val) { settings.borderColor = val; refresh(); }),
		function() { return settings.borderColor }	];
	widgets[10] = [ "Border Opacity",	new textBox(TEXTBOX_INPUT.number, function(val) { settings.borderAlpha = val; refresh(); }),
		function() { return settings.borderAlpha }	];
	
	b_export = button(function() { #region
		if(!is_surface(surface)) return;
		
		var path = get_save_filename("*.png", "Screenshot");
		if(path == -1) return;
		
		if(filename_ext(path) != ".png") path += ".png";
		surface_save(surface, path);
		noti_status($"Graph image exported at {path}");
	}); #endregion
	
	sc_settings = new scrollPane(w - ui(padding + padding), h - ui(title_height + padding + 204), function(_y, _m) { #region
		draw_clear_alpha(COLORS.panel_bg_clear, 0);
		
		var _ww = ui(160);
		var _hh = ui(30);
		var _ss = ui(28);
		var ty  = _y + _hh / 2;
		var _tx = sc_settings.surface_w;
		var wh = ui(36);
		
		for( var i = 0, n = array_length(widgets); i < n; i++ ) {
			draw_set_text(f_p1, fa_left, fa_center, COLORS._main_text);
			draw_text_add(0, ty + wh * i, __txt(widgets[i][0], "graph_export_"));
			
			var _wid = widgets[i][1];
			var _dat = widgets[i][2]();
			_wid.setFocusHover(pFOCUS, pHOVER);
			
			switch(instanceof(widgets[i][1])) {
				case "textBox" :	 _wid.draw(_tx - _ww, ty + wh * i - _hh / 2, _ww, _hh,		_dat, _m); break;
				case "checkBox" :	 _wid.draw(_tx - _ww / 2 - _ss / 2, ty + wh * i - _ss / 2,	_dat, _m); break;
				case "buttonColor" : _wid.draw(_tx - _ww, ty + wh * i - _hh / 2, _ww, _hh,		_dat, _m); break;
				case "scrollBox" :	 _wid.draw(_tx - _ww, ty + wh * i - _hh / 2, _ww, _hh,		_dat, _m, sc_settings.x + x, sc_settings.y + y); break;
			}
		}
		
		var _h = wh * array_length(widgets) + _hh;
		return _h;
	}); #endregion
	
	function onResize() { #region
		sc_settings.resize(w - ui(padding + padding), h - ui(title_height + padding + 204));
	} #endregion
	
	function refresh() { #region
		if(is_surface(surface))
			surface_free(surface);
		surface = noone;
			
		if(nodeList == noone)
			return;
			
		surface = graph_export_image(targetPanel.nodes_list, nodeList, settings);
	} refresh(); #endregion
	
	function drawContent(panel) { #region
		var tx = padding;
		var ty = padding;
		var sh = 160;
		
		if(is_surface(surface)) {
			var _sw = surface_get_width_safe(surface);
			var _sh = surface_get_height_safe(surface);
			
			var ss = min((w - padding * 2) / _sw, sh / _sh);
			draw_surface_ext_safe(surface, w / 2 - _sw * ss / 2, ty + sh / 2 - _sh * ss / 2, ss, ss, 0, c_white, 1);
			
			draw_set_text(f_p2, fa_center, fa_bottom, COLORS._main_text_sub);
			draw_text_add(w / 2, ty + sh - ui(2), $"{surface_get_width_safe(surface)} x {surface_get_height_safe(surface)} px");
		}
		
		draw_set_color(COLORS._main_icon);
		draw_rectangle(tx, ty, tx + w - padding * 2, ty + sh, 1);
		
		var bx = w - padding - ui(4) - ui(24);
		var by = padding + ui(4);
		var _m = [ mx, my ];
		
		if(buttonInstant(THEME.button_hide, bx, by, ui(24), ui(24), _m, pFOCUS, pHOVER) == 2)
			refresh();
		draw_sprite_ui(THEME.refresh_s, 0, bx + ui(12), by + ui(12),,,, COLORS._main_icon, 1);
		
		var sx = tx;
		var sy = ty + sh + ui(16);
		
		sc_settings.setFocusHover(pFOCUS, pHOVER);
		sc_settings.draw(sx, sy, mx - sx, my - sy);
		
		var txt = __txt("Export") + "...";
		draw_set_text(f_p1, fa_left, fa_top, COLORS._main_text);
		var _bw = string_width(txt) + ui(32);
		var _bh = string_height(txt) + ui(12);
		bx = w - padding - _bw;
		by = h - padding - _bh;
			
		b_export.setInteract(is_surface(surface));
		b_export.setFocusHover(pFOCUS, pHOVER);
		b_export.draw(bx, by, _bw, _bh, _m);
		
		draw_set_alpha(is_surface(surface) * 0.5 + 0.5);
		draw_text(bx + ui(16), by + ui(6), txt);
		draw_set_alpha(1);
	} #endregion
}