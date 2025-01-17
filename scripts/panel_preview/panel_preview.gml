function Panel_Preview() : PanelContent() constructor {
	title = __txt("Preview");
	context_str = "Preview";
	icon  = THEME.panel_preview;
	
	last_focus = noone;
	
	#region ---- canvas control & sample ----
		function initSize() {
			canvas_x = w / 2;
			canvas_y = h / 2;
		}
		run_in(1, function() { initSize() });
	
		canvas_x = 0;
		canvas_y = 0;
		canvas_s = ui(1);
		canvas_w = ui(128);
		canvas_h = ui(128);
		canvas_a = 0;
	
		canvas_bg = -1;
	
		do_fullView = false;
	
		canvas_hover = true;
		canvas_dragging_key = false;
		canvas_dragging = false;
		canvas_drag_key = 0;
		canvas_drag_mx  = 0;
		canvas_drag_my  = 0;
		canvas_drag_sx  = 0;
		canvas_drag_sy  = 0;
	
		canvas_zooming_key = false;
		canvas_zooming  = false;
		canvas_zoom_mx  = 0;
		canvas_zoom_my  = 0;
		canvas_zoom_m   = 0;
		canvas_zoom_s   = 0;
		
		sample_color = noone;
		sample_x = noone;
		sample_y = noone;
	
	#endregion
	
	#region ---- preview ----
		preview_node	= [ noone, noone ];
		preview_surface = [ 0, 0 ];
		tile_surface    = surface_create(1, 1);
	
		preview_x		= 0;
		preview_x_to	= 0;
		preview_x_max	= 0;
		preview_sequence  = [ 0, 0 ];
		_preview_sequence = preview_sequence;
		preview_rate      = 10;
		
		right_menu_y      = 8;
		mouse_on_preview  = 0;
		_mouse_on_preview = 0;
		
		resetViewOnDoubleClick = true;
	
		splitView		= 0;
		splitPosition	= 0.5;
		splitSelection	= 0;
	
		splitViewDragging = false;
		splitViewStart  = 0;
		splitViewMouse  = 0;
	
		tileMode = 0;
		
		bg_color = COLORS.panel_bg_clear;
	#endregion
	
	#region ---- tool ----
		tool_x       = 0;
		tool_x_to    = 0;
		tool_x_max   = 0;
		tool_current = noone;
		
		tool_hovering     = false;
		tool_side_drawing = false;
		overlay_hovering  = false;
		
		sbChannel = new scrollBox([], function(index) { #region
			var node = getNodePreview();
			if(node == noone) return;
		
			node.preview_channel = array_safe_get(sbChannelIndex, index); 
		}); #endregion
		sbChannelIndex  = [];
		sbChannel.font  = f_p1;
		sbChannel.align = fa_left;
	#endregion
	
	#region ---- 3d ----
		d3_active  = false;
		_d3_active = false;
		d3_active_transition = 0;
		
		d3_surface = noone;
		d3_surface_normal  = noone;
		d3_surface_depth   = noone;
		d3_surface_outline = noone;
		d3_surface_bg      = noone;
		d3_preview_channel = 0;
		
		d3_deferData = noone;
		
		global.SKY_SPHERE = new __3dUVSphere(0.5, 16, 8, true);
		
		#region camera
			d3_view_camera = new __3dCamera();
			d3_camW = 1;
			d3_camH = 1;
		
			d3_view_camera.setFocusAngle(135, 45, 4);
			d3_camLerp = false;
	
			d3_camTarget = new __vec3();
		
			d3_camPanning = false;
			d3_camPan_mx  = 0;
			d3_camPan_my  = 0;
		
			d3_zoom_speed = 0.2;
			d3_pan_speed  = 2;
		#endregion
		
		#region scene
			d3_scene  = new __3dScene(d3_view_camera, "Preview");
			d3_scene.lightAmbient = $404040;
			d3_scene.cull_mode    = cull_counterclockwise;
			d3_scene_preview	  = d3_scene;
			
			d3_scene_light_enabled = true;
			
			d3_scene_light0 = new __3dLightDirectional();
			d3_scene_light0.transform.position.set(-1, -2, 3);
			d3_scene_light0.color  = $FFFFFF;
			d3_scene_light0.shadow_active = false;
			d3_scene_light0.shadow_map_scale = 4;
			
			d3_scene_light1 = new __3dLightDirectional();
			d3_scene_light1.transform.position.set(1, 2, -3);
			d3_scene_light1.color  = $505050;
		#endregion
		
		#region tool
			d3_tool_snap = false;
			d3_tool_snap_position = 1;
			d3_tool_snap_rotation = 15;
		#endregion
		
		#region shadow map
			
		#endregion
		
		#region view channel
			d3ChannelNames = [ "Rendered", "Normal", "Depth" ];
			d3Channel = new scrollBox(d3ChannelNames, function(index) { d3_preview_channel = index; });
			d3Channel.align = fa_left;
		#endregion
	#endregion
	
	tb_framerate = new textBox(TEXTBOX_INPUT.number, function(val) { preview_rate = real(val); });
	
	#region ++++ toolbars & actions ++++
	topbar_height  = ui(32);
	toolbar_height = ui(40);
	toolbars = [
		[ 
			THEME.icon_reset_when_preview,
			function() { return resetViewOnDoubleClick;  },
			function() { return resetViewOnDoubleClick? __txtx("panel_preview_center_canvas_on_preview", "Center canvas on preview") :
					__txtx("panel_preview_keep_canvas_on_preview", "Keep canvas on preview"); }, 
			function() { resetViewOnDoubleClick = !resetViewOnDoubleClick; } 
		],
		[ 
			THEME.icon_split_view,
			function() { return splitView;  },
			function() { 
				switch(splitView) {
					case 0 : return __txtx("panel_preview_split_view_off", "Split view off");
					case 1 : return __txtx("panel_preview_horizontal_split_view", "Horizontal split view");
					case 2 : return __txtx("panel_preview_vertical_split_view", "Vertical split view");
				}
				return __txtx("panel_preview_split_view", "Split view");
			}, 
			function() { splitView = (splitView + 1) % 3; } 
		],
		[
			THEME.icon_tile_view,
			function() { var t = [3, 0, 1, 2]; return array_safe_get(t, tileMode);  },
			function() { 
				switch(tileMode) {
					case 0 : return __txtx("panel_preview_tile_off", "Tile off");
					case 1 : return __txtx("panel_preview_tile_horizontal", "Tile horizontal");
					case 2 : return __txtx("panel_preview_tile_vertical", "Tile vertical");
					case 3 : return __txtx("panel_preview_tile_both", "Tile both");
				}
				return __txtx("panel_preview_tile_mode", "Tile mode");
			}, 
			function(data) { 
				menuCall("preview_tile_menu", data.x + ui(28), data.y + ui(28), [
					menuItem(__txtx("panel_preview_tile_off", "Tile off"),					function() { tileMode = 0; }),
					menuItem(__txtx("panel_preview_tile_horizontal", "Tile horizontal"),	function() { tileMode = 1; }),
					menuItem(__txtx("panel_preview_tile_vertical", "Tile vertical"),		function() { tileMode = 2; }),
					menuItem(__txtx("panel_preview_tile_both", "Tile both"),				function() { tileMode = 3; }),
				]);
			} 
		],
		[ 
			THEME.icon_grid_setting,
			function() { return 0; },
			function() { return __txtx("grid_title", "Grid setting") }, 
			function(param) { 
				var dia = dialogPanelCall(new Panel_Preview_Grid_Setting(), param.x, param.y, { anchor: ANCHOR.bottom | ANCHOR.left }); 
			} 
		],
		[ 
			THEME.onion_skin,
			function() { return 0; },
			function() { return __txt("Onion Skin") }, 
			function(param) { 
				var dia = dialogPanelCall(new Panel_Preview_Onion_Setting(), param.x, param.y, { anchor: ANCHOR.bottom | ANCHOR.left }); 
			} 
		],
	];
	
	toolbars_3d = [
		[ 
			THEME.d3d_preview_settings,
			function() { return 0; },
			function() { return __txt("3D Preview Settings") }, 
			function(param) { 
				var dia = dialogPanelCall(new Panel_Preview_3D_Setting(self), param.x, param.y, { anchor: ANCHOR.bottom | ANCHOR.left }); 
			} 
		],
		[ 
			THEME.d3d_snap_settings,
			function() { return 0; },
			function() { return __txt("3D Snap Settings") }, 
			function(param) { 
				var dia = dialogPanelCall(new Panel_Preview_Snap_Setting(self), param.x, param.y, { anchor: ANCHOR.bottom | ANCHOR.left }); 
			} 
		],
	];
	
	actions = [
		[ 
			THEME.icon_preview_export,
			__txtx("panel_preview_export_canvas", "Export canvas"), 
			function() { saveCurrentFrame(); }
		],
		[ 
			THEME.icon_center_canvas,
			__txtx("panel_preview_center_canvas", "Center canvas"), 
			function() { fullView(); }
		],
		
	]
	#endregion
	
	#region ++++ hotkey ++++
	addHotkey("Preview", "Focus content",			"F", MOD_KEY.none,	function() { PANEL_PREVIEW.fullView(); });
	addHotkey("Preview", "Save current frame",		"S", MOD_KEY.shift,	function() { PANEL_PREVIEW.saveCurrentFrame(); });
	addHotkey("Preview", "Save all current frame",	-1, MOD_KEY.none,	function() { PANEL_PREVIEW.saveAllCurrentFrames(); });
	addHotkey("Preview", "Preview window",			"P", MOD_KEY.ctrl,	function() { create_preview_window(PANEL_PREVIEW.getNodePreview()); });
	addHotkey("Preview", "Toggle grid",				"G", MOD_KEY.ctrl,	function() { PROJECT.previewGrid.show = !PROJECT.previewGrid.show; });
	
	addHotkey("Preview", "Pan",		"", MOD_KEY.ctrl,				function() { PANEL_PREVIEW.canvas_dragging_key = true; });
	addHotkey("Preview", "Zoom",	"", MOD_KEY.alt | MOD_KEY.ctrl,	function() { PANEL_PREVIEW.canvas_zooming_key  = true; });
	#endregion
	
	function setNodePreview(node) { #region
		if(resetViewOnDoubleClick)
			do_fullView = true;
		
		if(is_instanceof(node, Node) && node.getPreviewingNode != noone)
			node = node.getPreviewingNode();
		
		preview_node[splitView? splitSelection : 0] = node;
	} #endregion
	
	function removeNodePreview(node) { #region
		if(preview_node[0] == node) preview_node[0] = noone;
		if(preview_node[1] == node) preview_node[1] = noone;
	} #endregion
	
	function resetNodePreview() { preview_node = [ noone, noone ]; }
	
	function getNodePreview()			{ return preview_node[splitView? splitSelection : 0]; }
	function getNodePreviewSurface()	{ return preview_surface[splitView? splitSelection : 0]; }
	function getNodePreviewSequence()	{ return preview_sequence[splitView? splitSelection : 0]; }
	
	function getPreviewData() { #region
		preview_surface  = [ noone, noone ];
		preview_sequence = [ noone, noone ];
		
		for( var i = 0; i < 2; i++ ) {
			var node = preview_node[i];
			
			if(node == noone) continue;
			if(!node.active) {
				resetNodePreview();
				return;
			}
			
			var value = node.getPreviewValues();
			
			if(is_array(value)) {
				preview_sequence[i] = value;
				canvas_a = array_length(value);
			} else {
				preview_surface[i] = value;
				canvas_a = 0;
			}
			
			if(preview_sequence[i] != noone) {
				if(array_length(preview_sequence[i]) == 0) return;
				preview_surface[i] = preview_sequence[i][safe_mod(node.preview_index, array_length(preview_sequence[i]))];
			}
		}
		
		var prevS = getNodePreviewSurface();
		if(is_surface(prevS)) {
			canvas_w = surface_get_width_safe(prevS);
			canvas_h = surface_get_height_safe(prevS);	
		}
	} #endregion
	
	function onFocusBegin() { PANEL_PREVIEW = self; }
	
	function dragCanvas() { #region
		if(canvas_dragging) {
			if(!MOUSE_WRAPPING) {
				var dx = mx - canvas_drag_mx;
				var dy = my - canvas_drag_my;
				
				canvas_x += dx;
				canvas_y += dy;
			}
			
			canvas_drag_mx = mx;
			canvas_drag_my = my;
			setMouseWrap();
			
			if(mouse_release(canvas_drag_key)) 
				canvas_dragging = false;
		}
		
		if(canvas_zooming) {
			if(!MOUSE_WRAPPING) {
				var dy = -(my - canvas_zoom_m) / 200;
				
				var _s = canvas_s;
				canvas_s = clamp(canvas_s * (1 + dy), 0.10, 64);
				
				if(_s != canvas_s) {
					var dx = (canvas_s - _s) * ((canvas_zoom_mx - canvas_x) / _s);
					var dy = (canvas_s - _s) * ((canvas_zoom_my - canvas_y) / _s);
					canvas_x -= dx;
					canvas_y -= dy;
				}
			}
				
			canvas_zoom_m = my;
			setMouseWrap();
			
			if(mouse_release(canvas_drag_key)) 
				canvas_zooming = false;
		}
		
		if(pFOCUS && pHOVER && canvas_hover) {
			var _doDragging = false;
			var _doZooming  = false;
			
			if(mouse_press(PREFERENCES.pan_mouse_key)) {
				_doDragging = true;
				canvas_drag_key = PREFERENCES.pan_mouse_key;
			} else if(mouse_press(mb_left) && canvas_dragging_key) {
				_doDragging = true;
				canvas_drag_key = mb_left;
			} else if(mouse_press(mb_left) && canvas_zooming_key) {
				_doZooming = true;
				canvas_drag_key = mb_left;
			}
			
			if(_doDragging) {
				canvas_dragging = true;	
				canvas_drag_mx  = mx;
				canvas_drag_my  = my;
				canvas_drag_sx  = canvas_x;
				canvas_drag_sy  = canvas_y;
			}
			
			if(_doZooming) {
				canvas_zooming  = true;	
				canvas_zoom_mx  = mx;
				canvas_zoom_my  = my;
				canvas_zoom_m   = my;
				canvas_zoom_s   = canvas_s;
			}
			
			var _canvas_s = canvas_s;
			var inc = 0.1;
			if(canvas_s > 16)		inc = 2;
			else if(canvas_s > 8)	inc = 1;
			else if(canvas_s > 3)	inc = 0.5;
			else if(canvas_s > 1)	inc = 0.25;
			
			if(mouse_wheel_down()) canvas_s = max(round(canvas_s / inc) * inc - inc, 0.10);
			if(mouse_wheel_up())   canvas_s = min(round(canvas_s / inc) * inc + inc, 64);
			if(_canvas_s != canvas_s) {
				var dx = (canvas_s - _canvas_s) * ((mx - canvas_x) / _canvas_s);
				var dy = (canvas_s - _canvas_s) * ((my - canvas_y) / _canvas_s);
				canvas_x -= dx;
				canvas_y -= dy;
			}
		}
		
		canvas_dragging_key = false;
		canvas_zooming_key  = false;
		canvas_hover = point_in_rectangle(mx, my, 0, toolbar_height, w, h - toolbar_height);
	} #endregion
	
	function dragCanvas3D() { #region
		if(d3_camPanning) {
			if(!MOUSE_WRAPPING) {
				var dx = mx - d3_camPan_mx;
				var dy = my - d3_camPan_my;
				
				d3_view_camera.focus_angle_x += dx * 0.2 * d3_pan_speed;
				d3_view_camera.focus_angle_y += dy * 0.1 * d3_pan_speed;
			}
			
			d3_camPan_mx = mx;
			d3_camPan_my = my;
			setMouseWrap();
			
			if(mouse_release(canvas_drag_key)) 
				d3_camPanning = false;
		}
		
		if(canvas_zooming) {
			if(!MOUSE_WRAPPING) {
				var dy = -(my - canvas_zoom_m) / 200;
				d3_view_camera.focus_dist = clamp(d3_view_camera.focus_dist + dy, 1, 1000);
			}
				
			canvas_zoom_m = my;
			setMouseWrap();
			
			if(mouse_release(canvas_drag_key)) 
				canvas_zooming = false;
		}
		
		if(pFOCUS && pHOVER && canvas_hover) {
			var _doDragging = false;
			var _doZooming  = false;
			
			if(mouse_press(PREFERENCES.pan_mouse_key)) {
				_doDragging = true;
				canvas_drag_key = PREFERENCES.pan_mouse_key;
			} else if(mouse_press(mb_left) && canvas_dragging_key) {
				_doDragging = true;
				canvas_drag_key = mb_left;
			} else if(mouse_press(mb_left) && canvas_zooming_key) {
				_doZooming = true;
				canvas_drag_key = mb_left;
			}
			
			if(_doDragging) {
				d3_camPanning = true;
				d3_camPan_mx  = mx;
				d3_camPan_my  = my;
			}
			
			if(_doZooming) {
				canvas_zooming  = true;	
				canvas_zoom_m   = my;
			}
			
			if(mouse_wheel_up())   d3_view_camera.focus_dist = max(   1, d3_view_camera.focus_dist * (1 - d3_zoom_speed));
			if(mouse_wheel_down()) d3_view_camera.focus_dist = min(1000, d3_view_camera.focus_dist * (1 + d3_zoom_speed));
		}
		
		canvas_dragging_key = false;
		canvas_zooming_key  = false;
		canvas_hover = point_in_rectangle(mx, my, 0, toolbar_height, w, h - toolbar_height);
	} #endregion
	
	function fullView() { #region
		var bbox = noone;
		
		var node = getNodePreview();
		if(node != noone) bbox = node.getPreviewBoundingBox();
		if(bbox == noone) bbox = BBOX().fromWH(0, 0, PROJECT.attributes.surface_dimension[0], PROJECT.attributes.surface_dimension[1]);
		
		var ss = min((w - 32 - tool_side_drawing * 40) / bbox.w, (h - 32 - toolbar_height * 2) / bbox.h);
		canvas_s = ss;
		canvas_x = w / 2 - bbox.w * canvas_s / 2 - bbox.x0 * canvas_s + (tool_side_drawing * 40 / 2);
		canvas_y = h / 2 - bbox.h * canvas_s / 2 - bbox.y0 * canvas_s;
	} #endregion
	
	function drawNodeChannel(_x, _y) { #region
		var _node = getNodePreview();
		if(_node == noone) return;
		if(ds_list_size(_node.outputs) < 2) return;
		
		var chName = [];
		sbChannelIndex = [];
		
		var currName = _node.outputs[| _node.preview_channel].name;
		draw_set_text(sbChannel.font, fa_center, fa_center);
		var ww = 0;
		var hh = TEXTBOX_HEIGHT - ui(2);
		
		for( var i = 0; i < ds_list_size(_node.outputs); i++ ) {
			if(_node.outputs[| i].type != VALUE_TYPE.surface) continue;
			
			array_push(chName, _node.outputs[| i].name);
			array_push(sbChannelIndex, i);
			ww = max(ww, string_width(_node.outputs[| i].name) + ui(40));
		}
		
		sbChannel.data_list = chName;
		sbChannel.setFocusHover(pFOCUS, pHOVER);
		sbChannel.draw(_x - ww, _y - hh / 2, ww, hh, currName, [mx, my], x, y);
		right_menu_y += ui(40);
	} #endregion
	
	function drawNodeChannel3D(_x, _y) { #region
		var _node = getNodePreview();
		if(_node == noone) return;
		
		var ww = ui(128);
		var hh = toolbar_height - ui(12);
		
		d3Channel.setFocusHover(pFOCUS, pHOVER);
		d3Channel.draw(_x - ww, _y - hh / 2, ww, hh, d3ChannelNames[d3_preview_channel], [mx, my], x, y);
		right_menu_y += ui(40);
	} #endregion
	
	function drawOnionSkin(node, psx, psy, ss) { #region
		var _surf = preview_surface[0];
		var _rang = PROJECT.onion_skin.range;
		
		var _alph = PROJECT.onion_skin.alpha;
		var _colr = PROJECT.onion_skin.color;
		
		var _step = PROJECT.onion_skin.step;
		var _top  = PROJECT.onion_skin.on_top;
		
		var fr = CURRENT_FRAME;
		var st = min(_rang[0], _rang[1]);
		var ed = max(_rang[0], _rang[1]);
			
		st = sign(st) * floor(abs(st) / _step) * _step;
		ed = sign(ed) * floor(abs(ed) / _step) * _step;
			
		st += fr;
		ed += fr;
			
		for( var i = st; i <= ed; i += _step ) {
			var surf = node.getCacheFrame(i);
			if(!is_surface(surf)) continue;
				
			var aa = power(_alph, abs((i - fr) / _step));
			var cc = c_white;
			if(i < fr)		cc = _colr[0];
			else if(i > fr) cc = _colr[1];
				
			draw_surface_ext_safe(surf, psx, psy, ss, ss, 0, cc, aa);
		}
			
		if(_top) draw_surface_ext_safe(_surf, psx, psy, ss, ss);
	} #endregion
	
	function drawNodePreview() { #region
		var ss   = canvas_s;
		var psx  = 0, psy  = 0;
		var psw  = 0, psh  = 0;
		var pswd = 0, pshd = 0;
		var psx1 = 0, psy1 = 0;
		
		var ssx = 0, ssy = 0;
		var ssw = 0, ssh = 0;
		
		if(is_surface(preview_surface[0])) {
			psx = canvas_x + preview_node[0].preview_x * ss;
			psy = canvas_y + preview_node[0].preview_y * ss;
			
			psw = surface_get_width_safe(preview_surface[0]);
			psh = surface_get_height_safe(preview_surface[0]);
			pswd = psw * ss;
			pshd = psh * ss;
			
			psx1 = psx + pswd;
			psy1 = psy + pshd;	
		}
		
		if(is_surface(preview_surface[1])) {
			var ssx = canvas_x + preview_node[1].preview_x * ss;
			var ssy = canvas_y + preview_node[1].preview_y * ss;
			
			var ssw = surface_get_width_safe(preview_surface[1]);
			var ssh = surface_get_height_safe(preview_surface[1]);
		}
		
		var _node = getNodePreview();
		if(_node) title = _node.renamed? _node.display_name : _node.name;
		
		if(splitView == 0 && tileMode == 0) {
			var node = preview_node[0];
			if(is_surface(preview_surface[0])) {
				node.previewing = 1;
				var aa = node.preview_alpha;
			
				if(PROJECT.onion_skin.enabled) drawOnionSkin(node, psx, psy, ss); 
				else                           draw_surface_ext_safe(preview_surface[0], psx, psy, ss, ss, 0, c_white, aa); 
			}
		}
		
		switch(splitView) { #region draw surfaces
			case 0 :
				if(is_surface(preview_surface[0])) {
					preview_node[0].previewing = 1;
					
					switch(tileMode) {
						case 1 : 
							tile_surface = surface_verify(tile_surface, w, surface_get_height_safe(preview_surface[0]) * ss);
							surface_set_target(tile_surface);
								DRAW_CLEAR
								draw_surface_tiled_ext_safe(preview_surface[0], psx, 0, ss, ss, c_white, 1); 
							surface_reset_target();
							draw_surface_safe(tile_surface, 0, psy);
							break;
						case 2 : 
							tile_surface = surface_verify(tile_surface, surface_get_width_safe(preview_surface[0]) * ss, h);
							surface_set_target(tile_surface);
								DRAW_CLEAR
								draw_surface_tiled_ext_safe(preview_surface[0], 0, psy, ss, ss, c_white, 1); 
							surface_reset_target();
							draw_surface_safe(tile_surface, psx, 0);
							break;
						case 3 : draw_surface_tiled_ext_safe(preview_surface[0], psx, psy, ss, ss, c_white, 1); break;
					}
				}
				break;
			case 1 :
				var sp = splitPosition * w;
				
				if(is_surface(preview_surface[0])) {
					preview_node[0].previewing = 2;
					var maxX = min(sp, psx1);
					var sW = min(psw, (maxX - psx) / ss);
					
					if(sW > 0)
						draw_surface_part_ext_safe(preview_surface[0], 0, 0, sW, psh, psx, psy, ss, ss, 0, c_white, 1);
				}
				
				if(is_surface(preview_surface[1])) {
					preview_node[1].previewing = 3;
					var minX = max(ssx, sp);
					var sX = (minX - ssx) / ss;
					var spx = max(sp, ssx);
					
					if(sX >= 0 && sX < ssw)
						draw_surface_part_ext_safe(preview_surface[1], sX, 0, ssw - sX, ssh, spx, ssy, ss, ss, 0, c_white, 1);
				}
				break;
			case 2 :
				var sp = splitPosition * h;
					
				if(is_surface(preview_surface[0])) {
					preview_node[0].previewing = 4;
					var maxY = min(sp, psy1);
					var sH = min(psh, (maxY - psy) / ss);
					
					if(sH > 0)
						draw_surface_part_ext_safe(preview_surface[0], 0, 0, psw, sH, psx, psy, ss, ss, 0, c_white, 1);
				}
				
				if(is_surface(preview_surface[1])) {
					preview_node[1].previewing = 5;
					var minY = max(ssy, sp);
					var sY = (minY - ssy) / ss;
					var spy = max(sp, ssy);
					
					if(sY >= 0 && sY < ssh)
						draw_surface_part_ext_safe(preview_surface[1], 0, sY, ssw, ssh - sY, ssx, spy, ss, ss, 0, c_white, 1);
				}
				break;
		} #endregion
		
		if(!instance_exists(o_dialog_menubox)) { #region color sample
			sample_color = noone;
			sample_x = noone;
			sample_y = noone;
		
			if(mouse_on_preview && (mouse_press(mb_right) || key_mod_press(CTRL))) {
				var _sx = sample_x;
				var _sy = sample_y;
				
				sample_x = floor((mx - canvas_x) / canvas_s);
				sample_y = floor((my - canvas_y) / canvas_s);
				var surf = getNodePreviewSurface();
				if(is_surface(surf))
					sample_color = surface_get_pixel_ext(surf, sample_x, sample_y);
			}
		} #endregion
		
		if(is_surface(preview_surface[0])) { #region outline
			if(PROJECT.previewGrid.show) {
				var _gw = PROJECT.previewGrid.size[0] * canvas_s;
				var _gh = PROJECT.previewGrid.size[1] * canvas_s;
				
				var gw = pswd / _gw;
				var gh = pshd / _gh;
			
				var cx = canvas_x;
				var cy = canvas_y;
			
				draw_set_color(PROJECT.previewGrid.color);
				draw_set_alpha(PROJECT.previewGrid.opacity);
				
				for( var i = 1; i < gw; i++ ) {
					var _xx = cx + i * _gw;
					draw_line(_xx, cy, _xx, cy + pshd);
				}
			
				for( var i = 1; i < gh; i++ ) {
					var _yy = cy + i * _gh;
					draw_line(cx, _yy, cx + pswd, _yy);
				}
				
				draw_set_alpha(1);
			}
		
			draw_set_color(COLORS.panel_preview_surface_outline);
			draw_rectangle(psx, psy, psx + pswd - 1, psy + pshd - 1, true);
		} #endregion
	} #endregion
	
	function draw3D() { #region
		var _prev_node = getNodePreview();
		if(_prev_node == noone) return;
		if(!_prev_node.is_3D)   return;
		
		_prev_node.previewing = 1;
		
		d3_scene_preview = struct_has(_prev_node, "scene")? _prev_node.scene : d3_scene;
		d3_scene_preview.camera = d3_view_camera;
		
		#region view
			var _pos, targ, _blend = 1;
			
			targ = d3_camTarget;
			_pos = d3d_PolarToCart(targ.x, targ.y, targ.z, d3_view_camera.focus_angle_x, d3_view_camera.focus_angle_y, d3_view_camera.focus_dist);
			
			if(d3_active_transition == 1) {
				var _up  = new __vec3(0, 0, -1);
				
				d3_view_camera.position._lerp_float(_pos, 5, 0.1);
				d3_view_camera.focus._lerp_float(   targ, 5, 0.1);
				d3_view_camera.up._lerp_float(       _up, 5, 0.1);
				
				if(d3_view_camera.position.equal(_pos) && d3_view_camera.focus.equal(targ))
					d3_active_transition = 0;
			} else if(d3_active_transition == -1) {
				var _pos = new __vec3(0, 0, 8);
				var targ = new __vec3(0, 0, 0);
				var _up  = new __vec3(0, 1, 0);
				
				d3_view_camera.position._lerp_float(_pos, 5, 0.1);
				d3_view_camera.focus._lerp_float(   targ, 5, 0.1);
				d3_view_camera.up._lerp_float(       _up, 5, 0.1);
				
				_blend = d3_view_camera.position.distance(_pos) / 2;
				_blend = clamp(_blend, 0, 1);
				
				if(d3_view_camera.position.equal(_pos) && d3_view_camera.focus.equal(targ))
					d3_active_transition = 0;
			} else {
				d3_view_camera.position.set(_pos);
				d3_view_camera.focus.set(targ);
			}
			
			d3_view_camera.setViewSize(w, h);
			d3_view_camera.setMatrix();
		#endregion
		
		#region background
			surface_free_safe(d3_surface_bg);
			
			if(d3_scene_preview != d3_scene)
				d3_surface_bg = d3_scene_preview.renderBackground(w, h);
		#endregion
		
		#region shadow
			if(d3_scene_preview == d3_scene) {
				d3_scene_light0.shadow_map_scale = d3_view_camera.focus_dist * 2;
				
				var _prev_obj = _prev_node.getPreviewObject();
				if(_prev_obj != noone) {
					d3_scene_light0.submitShadow(d3_scene_preview, _prev_obj);
					_prev_obj.submitShadow(d3_scene_preview, _prev_obj);
				}
			}
		#endregion
		
		d3_surface		   = surface_verify(d3_surface, w, h);
		d3_surface_normal  = surface_verify(d3_surface_normal, w, h);
		d3_surface_depth   = surface_verify(d3_surface_depth, w, h);
		d3_surface_outline = surface_verify(d3_surface_outline, w, h);
		
		#region defer
			var _prev_obj = _prev_node.getPreviewObject();
			d3_deferData  = d3_scene_preview.deferPass(_prev_obj, w, h, d3_deferData);
		#endregion
		
		#region grid
			surface_set_target_ext(0, d3_surface);
			surface_set_target_ext(1, d3_surface_normal);
			surface_set_target_ext(2, d3_surface_depth);
			
			draw_clear_alpha(bg_color, 0);
			
			d3_view_camera.applyCamera();
			
			gpu_set_cullmode(cull_noculling); 
			gpu_set_ztestenable(true);
			gpu_set_zwriteenable(false);
			
			shader_set(sh_d3d_grid_view);
				var _dist = round(d3_view_camera.focus.distance(d3_view_camera.position));
				var _tx   = round(d3_view_camera.focus.x);
				var _ty   = round(d3_view_camera.focus.y);
				
				var _scale = _dist * 2;
				while(_scale > 32) _scale /= 2;
				
				shader_set_f("axisBlend", _blend);
				shader_set_f("scale", _scale);
				shader_set_f("shift", _tx / _dist / 2, _ty / _dist / 2);
				draw_sprite_stretched(s_fx_pixel, 0, _tx - _dist, _ty - _dist, _dist * 2, _dist * 2);
			shader_reset();
			
			gpu_set_zwriteenable(true);
		#endregion
		
		#region draw
			d3_scene_preview.reset();
			gpu_set_cullmode(cull_counterclockwise); 
			
			var _prev_obj = _prev_node.getPreviewObjects();
				
			if(d3_scene_preview == d3_scene) {
				if(d3_scene_light_enabled) {
					d3_scene_preview.addLightDirectional(d3_scene_light0);
					d3_scene_preview.addLightDirectional(d3_scene_light1);
				}
			}
			
			for( var i = 0, n = array_length(_prev_obj); i < n; i++ ) {
				var _prev = _prev_obj[i];
				if(_prev == noone) continue;
					
				_prev.submitShader(d3_scene_preview);
			}
				
			d3_scene_preview.apply(d3_deferData);
			
			for( var i = 0, n = array_length(_prev_obj); i < n; i++ ) {
				var _prev = _prev_obj[i];
				if(_prev == noone) continue;
				_prev.submitUI(d3_scene_preview);							//////////////// SUBMIT ////////////////
			}
			
			gpu_set_cullmode(cull_noculling); 
			surface_reset_target();
			
			draw_clear(bg_color);
			
			switch(d3_preview_channel) {
				case 0 : 
					if(d3_scene_preview.draw_background)
						draw_surface_safe(d3_surface_bg);	
					
					draw_surface_safe(d3_surface);
					
					BLEND_MULTIPLY
					draw_surface_safe(d3_deferData.ssao);
					BLEND_NORMAL
					break;
				case 1 : draw_surface_safe(d3_surface_normal);	break;
				case 2 : draw_surface_safe(d3_surface_depth);	break;
			}
		#endregion
		
		#region outline
			var inspect_node = PANEL_INSPECTOR.getInspecting();
			
			if(inspect_node && inspect_node.is_3D) {
				var _inspect_obj = inspect_node.getPreviewObjectOutline();
				
				surface_set_target(d3_surface_outline);
				draw_clear(c_black);
					
				d3_scene_preview.camera.applyCamera();
					
				gpu_set_ztestenable(false);
					for( var i = 0, n = array_length(_inspect_obj); i < n; i++ ) {
						if(_inspect_obj[i] == noone) continue;
						_inspect_obj[i].submitSel(d3_scene_preview);
					}
				surface_reset_target();
					
				shader_set(sh_d3d_outline);
					shader_set_dim("dimension", d3_surface_outline);
					shader_set_color("outlineColor", COLORS._main_accent);
					draw_surface(d3_surface_outline, 0, 0);
				shader_reset();
			}
		#endregion
		
		d3_scene_preview.camera.resetCamera();
	} #endregion
	
	function drawPreviewOverlay() { #region
		right_menu_y = toolbar_height - ui(4);
		toolbar_draw = false;
		
		var _node = getNodePreview();
		
		#region status texts (top right)
			if(PANEL_PREVIEW == self) {
				draw_set_text(f_p0, fa_right, fa_top, COLORS._main_text_accent);
				draw_text(w - ui(8), right_menu_y, __txt("Active"));
				right_menu_y += string_height("l");
			}
		
			draw_set_text(f_p0, fa_right, fa_top, fps >= PROJECT.animator.framerate? COLORS._main_text_sub : COLORS._main_value_negative);
			draw_text(w - ui(8), right_menu_y, $"{__txt("fps")} {fps}");
			right_menu_y += string_height("l");
		
			draw_set_text(f_p0, fa_right, fa_top, COLORS._main_text_sub);
			draw_text(w - ui(8), right_menu_y, $"{__txt("Frame")} {CURRENT_FRAME}/{TOTAL_FRAMES}");
		
			right_menu_y += string_height("l");
			draw_text(w - ui(8), right_menu_y, $"x{canvas_s}");
		
			if(pHOVER) {
				right_menu_y += string_height("l");
				var mpx = floor((mx - canvas_x) / canvas_s);
				var mpy = floor((my - canvas_y) / canvas_s);
				draw_text(w - ui(8), right_menu_y, $"[{mpx}, {mpy}]");
			}
		
			if(_node == noone) return;
		
			right_menu_y += string_height("l");
			var txt = $"{canvas_w} x {canvas_h}px";
			if(canvas_a) txt = $"{canvas_a} x {txt}";
			draw_text(w - ui(8), right_menu_y, txt);
		
			right_menu_y += string_height("l");
		#endregion
		
		var pseq = getNodePreviewSequence();
		if(pseq == noone) return;
		
		if(!array_equals(pseq, _preview_sequence)) {
			_preview_sequence = pseq;
			preview_x    = 0;
			preview_x_to = 0;
		}
		
		var prev_size = ui(48);
		preview_x = lerp_float(preview_x, preview_x_to, 4);
			
		if(pHOVER && my > h - toolbar_height - prev_size - ui(16) && my > toolbar_height) {
			canvas_hover = false;
			
			if(mouse_wheel_down())	preview_x_to = clamp(preview_x_to - prev_size * SCROLL_SPEED, - preview_x_max, 0);
			if(mouse_wheel_up())	preview_x_to = clamp(preview_x_to + prev_size * SCROLL_SPEED, - preview_x_max, 0);
		}
			
		preview_x_max = 0;
		var _xx = tool_side_drawing * ui(40);
		var xx  = _xx + preview_x + ui(8);
		var yy  = h - toolbar_height - prev_size - ui(8);
		if(my > yy - 8) mouse_on_preview = 0;
		var hoverable = pHOVER && point_in_rectangle(mx, my, _xx, ui(32), w, h - toolbar_height);
		
		for(var i = 0; i < array_length(pseq); i++) {
			var prev   = pseq[i];
			if(is_instanceof(prev, __d3dMaterial))
				prev = prev.surface;
			if(!is_surface(prev)) continue;
				
			var prev_w = surface_get_width_safe(prev);
			var prev_h = surface_get_height_safe(prev);
			var ss     = prev_size / max(prev_w, prev_h);
			var prev_sw = prev_w * ss;
			
			draw_set_color(COLORS.panel_preview_surface_outline);
			draw_rectangle(xx, yy, xx + prev_w * ss, yy + prev_h * ss, true);
				
			if(hoverable && point_in_rectangle(mx, my, xx, yy, xx + prev_sw, yy + prev_h * ss)) {
				if(mouse_press(mb_left, pFOCUS)) {
					_node.preview_index = i;
					_node.onValueUpdate(0);
					if(resetViewOnDoubleClick)
						do_fullView = true;
				}
				draw_surface_ext_safe(prev, xx, yy, ss, ss, 0, c_white, 1);
			} else {
				draw_surface_ext_safe(prev, xx, yy, ss, ss, 0, c_white, 0.5);	
			}
				
			if(i == _node.preview_index) {
				draw_set_color(COLORS._main_accent);
				draw_rectangle(xx, yy, xx + prev_sw, yy + prev_h * ss, true);
			}
			
			xx += prev_sw + ui(8);
			preview_x_max += prev_sw + ui(8);
		}
		preview_x_max = max(preview_x_max - ui(100), 0);
		
		#region ++++ sequence control ++++
			//var by = h - toolbar_height - prev_size - ui(56);
			//var bx = ui(10);
			
			//var b = buttonInstant(THEME.button_hide, bx, by, ui(40), ui(40), [mx, my], pFOCUS, pHOVER);
			
			//if(_node.preview_speed == 0) {
			//	if(b) {
			//		draw_sprite_ui_uniform(THEME.sequence_control, 1, bx + ui(20), by + ui(20), 1, COLORS._main_icon, 1);
			//		if(b == 2) _node.preview_speed = preview_rate / game_get_speed(gamespeed_fps);
			//	}
			//	draw_sprite_ui_uniform(THEME.sequence_control, 1, bx + ui(20), by + ui(20), 1, COLORS._main_icon, 0.5);
			//} else {
			//	if(b) {
			//		draw_sprite_ui_uniform(THEME.sequence_control, 0, bx + ui(20), by + ui(20), 1, COLORS._main_accent, 1);
			//		if(b == 2) _node.preview_speed = 0;
			//	}
			//	draw_sprite_ui_uniform(THEME.sequence_control, 0, bx + ui(20), by + ui(20), 1, COLORS._main_accent, .75);
			//}
		#endregion
	} #endregion
	
	function drawNodeTools(active, _node) { #region
		var _mx = mx;
		var _my = my;
		var isHover = pHOVER && mouse_on_preview == 1;
		var tool_width = ui(40);
		var tool_size  = ui(32);
		
		var cx = canvas_x + _node.preview_x * canvas_s;
		var cy = canvas_y + _node.preview_y * canvas_s;
		var _snx = 0, _sny = 0;
		
		tool_side_drawing = _node.tools != -1;
		
		if(_node.tools != -1 && point_in_rectangle(_mx, _my, 0, 0, tool_width, h)) {
			isHover = false;
			mouse_on_preview = 0;
		}
		
		var overlayHover =  tool_hovering == noone && !overlay_hovering;
			overlayHover &= active && isHover;
			overlayHover &= point_in_rectangle(mx, my, 0, toolbar_height, w, h - toolbar_height);
			overlayHover &= !key_mod_press(CTRL);
		var params = { w, h, toolbar_height };
		
		if(_node.is_3D)	{
			if(key_mod_press(CTRL) || d3_tool_snap) {
				_snx = d3_tool_snap_position;
				_sny = d3_tool_snap_rotation;
			}
			
			_node.drawOverlay3D(overlayHover, d3_scene, _mx, _my, _snx, _sny, params);
		} else {
			if(key_mod_press(CTRL)) {
				_snx = PROJECT.previewGrid.show? PROJECT.previewGrid.size[0] : 1;
				_sny = PROJECT.previewGrid.show? PROJECT.previewGrid.size[1] : 1;
			} else if(PROJECT.previewGrid.snap) {
				_snx = PROJECT.previewGrid.size[0];
				_sny = PROJECT.previewGrid.size[1];
			}
		
			_node.drawOverlay(overlayHover, cx, cy, canvas_s, _mx, _my, _snx, _sny, params);
		}
		
		#region node overlay
			overlay_hovering = false;
		
			if(_node.drawPreviewToolOverlay(pHOVER && pFOCUS, _mx, _my, { x, y, w, h, toolbar_height, 
				x0: _node.tools == -1? 0 : ui(40),
				x1: w,
				y0: toolbar_height - ui(8), 
				y1: h - toolbar_height 
			})) {
				canvas_hover     = false;
				overlay_hovering = true;
			}
		#endregion
		
		var _tool = tool_hovering;
		tool_hovering = noone;
		
		if(_node.tools == -1) {
			tool_current = noone;
			return;
		}
		
		var aa = d3_active? 0.8 : 1;
		draw_sprite_stretched_ext(THEME.tool_side, 1, 0, ui(32), tool_width, h - toolbar_height - ui(32), c_white, aa);
			
		var xx = ui(1)  + tool_width / 2;
		var yy = ui(34) + tool_size / 2;
		var pd = 2;
			
		for(var i = 0; i < array_length(_node.tools); i++) { #region iterate each tools
			var tool = _node.tools[i];
			var _x0  = xx - tool_size / 2;
			var _y0  = yy - tool_size / 2;
			var _x1  = xx + tool_size / 2;
			var _y1  = yy + tool_size / 2;
				
			if(point_in_rectangle(_mx, _my, _x0, _y0 + 1, _x1, _y1 - 1)) {
				tool_hovering = tool;
			} 
				
			if(tool.subtools > 0 && _tool == tool) { #region subtools
				var s_ww = tool_size * tool.subtools;
				var s_hh = tool_size;
				draw_sprite_stretched(THEME.menu_bg, 0, _x0 - pd, _y0 - pd, s_ww + pd * 2, s_hh + pd * 2);
					
				var stool = tool.spr;
						
				for( var j = 0; j < array_length(stool); j++ ) {
					var _sxx = xx + j * tool_size;
					var _syy = yy;
							
					var _sx0  = _sxx - tool_size / 2;
					var _sy0  = _syy - tool_size / 2;
					var _sx1  = _sxx + tool_size / 2;
					var _sy1  = _syy + tool_size / 2;
				
					if(point_in_rectangle(_mx, _my, _sx0, _sy0 + 1, _sx1, _sy1 - 1)) {
						TOOLTIP = tool.getDisplayName(j);
						draw_sprite_stretched(THEME.button_hide, 1, _sx0 + pd, _sy0 + pd, tool_size - pd * 2, tool_size - pd * 2);
							
						if(mouse_press(mb_left, pFOCUS))
							tool.toggle(j);
					} 
							
					if(tool_current == tool && tool.selecting == j) {
						draw_sprite_stretched_ext(THEME.button_hide, 2, _sx0 + pd, _sy0 + pd, tool_size - pd * 2, tool_size - pd * 2, COLORS.panel_preview_grid, 1);
						draw_sprite_stretched_ext(THEME.button_hide, 3, _sx0 + pd, _sy0 + pd, tool_size - pd * 2, tool_size - pd * 2, COLORS._main_accent, 1);
					}
					
					draw_sprite_colored(stool[j], 0, _sxx, _syy);
				}
					
				if(point_in_rectangle(_mx, _my, _x0, _y0 + 1, _x0 + s_ww, _y1 - 1))
					tool_hovering = tool;
			#endregion
			} else { #region single tools
				if(tool_hovering == tool) {
					draw_sprite_stretched(THEME.button_hide, 1, _x0 + pd, _y0 + pd, tool_size - pd * 2, tool_size - pd * 2);
					TOOLTIP = tool.getDisplayName();
					
					if(mouse_press(mb_left, pFOCUS))
						tool.toggle();
				}
					
				if(pFOCUS && WIDGET_CURRENT == noone) {
					var _key = tool.checkHotkey();
					
					if(keyboard_check_pressed(ord(string(i + 1))) || (_key != "" && keyboard_check_pressed(ord(_key))))
						tool.toggleKeyboard();
				}
				
				if(tool_current == tool) {
					draw_sprite_stretched_ext(THEME.button_hide, 2, _x0 + pd, _y0 + pd, tool_size - pd * 2, tool_size - pd * 2, COLORS.panel_preview_grid, 1);
					draw_sprite_stretched_ext(THEME.button_hide, 3, _x0 + pd, _y0 + pd, tool_size - pd * 2, tool_size - pd * 2, COLORS._main_accent, 1);
				}
				
				if(tool.subtools > 0)	draw_sprite_colored(tool.spr[tool.selecting], 0, xx, yy);
				else					draw_sprite_colored(tool.spr, 0, xx, yy);
			#endregion
			}
				
			yy += tool_size;
		} #endregion
	} #endregion
	
	function drawToolBar(_node) { #region
		toolbar_height = ui(40);
		var ty = h - toolbar_height;
		//draw_sprite_stretched_ext(THEME.toolbar_shadow, 0, 0, ty - 12 + 4, w, 12, c_white, 0.5);
		
		var aa = d3_active? 0.8 : 1;
		draw_sprite_stretched_ext(THEME.toolbar, 1, 0, 0, w, topbar_height, c_white, aa);
		draw_sprite_stretched_ext(THEME.toolbar, 0, 0, ty, w, toolbar_height, c_white, aa);
		
		if(!_node) return;
		
		if(tool_current != noone) { #region tool settings
			var settings = array_merge(_node.getToolSettings(), tool_current.settings);
			
			tool_x = lerp_float(tool_x, tool_x_to, 5);
			var tolx  = tool_x + ui(16);
			var toly  = ui(8);
			var tolw  = ui(48);
			var tolh  = toolbar_height - ui(20);
			var tol_max_w = ui(32);
			
			for( var i = 0, n = array_length(settings); i < n; i++ ) {
				var sett = settings[i];
				var nme  = sett[0];
				var wdg  = sett[1];
				var key  = sett[2];
				var atr  = sett[3];
				
				draw_set_text(f_p2, fa_left, fa_center, COLORS._main_text_sub);
				draw_text(tolx, toolbar_height / 2 - ui(2), nme);
				tolx      += string_width(nme) + ui(8);
				tol_max_w += string_width(nme) + ui(8);
				
				wdg.setFocusHover(pFOCUS, pHOVER);
				
				switch(instanceof(wdg)) {
					case "checkBoxGroup" : tolw = tolh * wdg.size;	break;
					case "checkBox" :	   tolw = tolh;				break;
					case "scrollBox" :     tolw = ui(96);			break;
				}
				
				var params = new widgetParam(tolx, toly, tolw, tolh, atr[$ key],, [ mx, my ])
				params.s = tolh;
				
				wdg.drawParam(params);
				
				tolx	  += tolw + ui(16);
				tol_max_w += tolw + ui(16);
			}
			
			tol_max_w = max(0, tol_max_w - w);			
			if(point_in_rectangle(mx, my, 0, 0, w, toolbar_height)) {
				if(mouse_wheel_up())   tool_x_to = clamp(tool_x_to + ui(64) * SCROLL_SPEED, -tol_max_w, 0);
				if(mouse_wheel_down()) tool_x_to = clamp(tool_x_to - ui(64) * SCROLL_SPEED, -tol_max_w, 0);
			}
		#endregion
		} else { #region color sampler
			var cx = ui(10);
			var cy = ui(10);
			var cw = ui(32);
			var ch = topbar_height - ui(16);
			
			if(sample_color != noone) {
				draw_set_color(sample_color);
				draw_rectangle(cx, cy, cx + cw, cy + ch, false);
			}
		
			draw_set_color(COLORS.panel_toolbar_outline);
			draw_rectangle(cx, cy, cx + cw, cy + ch, true);
			
			if(sample_color != noone) {
				var tx = cx + cw + ui(16);
				var hx = color_get_hex(sample_color);
				draw_set_text(f_p0, fa_left, fa_center, COLORS._main_text);
				draw_text(tx, cy + ch / 2, hx);
			
				tx += string_width(hx) + ui(8);
				draw_set_color(COLORS._main_text_sub);
				draw_text(tx, cy + ch / 2, "(" + string(color_get_alpha(sample_color)) + ")");
			}
		#endregion
		}
		
		var tbx = toolbar_height / 2;
		var tby = ty + toolbar_height / 2;
		
		var _toolbars = d3_active? toolbars_3d : toolbars;
		
		for( var i = 0, n = array_length(_toolbars); i < n; i++ ) {
			var tb = _toolbars[i];
			var tbSpr     = tb[0];
			var tbInd     = tb[1]();
			var tbTooltip = tb[2]();
			var tbActive  = tb[3];
			
			var b = buttonInstant(THEME.button_hide, tbx - ui(14), tby - ui(14), ui(28), ui(28), [mx, my], pFOCUS, pHOVER, tbTooltip, tbSpr, tbInd);
			if(b == 2) tbActive( { x: x + tbx - ui(14), y: y + tby - ui(14) } );
			
			tbx += ui(32);
		}
		
		tbx = w - toolbar_height / 2;
		for( var i = 0, n = array_length(actions); i < n; i++ ) {
			var tb = actions[i];
			var tbSpr = tb[0];
			var tbTooltip = tb[1];
			
			var b = buttonInstant(THEME.button_hide, tbx - ui(14), tby - ui(14), ui(28), ui(28), [mx, my], pFOCUS, pHOVER, tbTooltip, tbSpr, 0);
			if(b == 2) tb[2]();
			
			tbx -= ui(32);
		}
		
		draw_set_color(COLORS.panel_toolbar_separator);
		draw_line_width(tbx + ui(12), tby - toolbar_height / 2 + ui(8), tbx + ui(12), tby + toolbar_height / 2 - ui(8), 2);
		
		if(d3_active)	drawNodeChannel3D(tbx, tby);
		else			drawNodeChannel(tbx, tby);
	} #endregion
	
	function drawSplitView() { #region
		if(splitView == 0) return;
		
		draw_set_color(COLORS.panel_preview_split_line);
		
		if(splitViewDragging) {
			if(splitView == 1) {
				var cx = splitViewStart + (mx - splitViewMouse);
				splitPosition = clamp(cx / w, .1, .9);
			} else if(splitView == 2) {
				var cy = splitViewStart + (my - splitViewMouse);
				splitPosition = clamp(cy / h, .1, .9);
			}
			
			if(mouse_release(mb_left))
				splitViewDragging = false;
		}
		
		if(splitView == 1) {
			var sx = w * splitPosition;
			
			if(mouse_on_preview && point_in_rectangle(mx, my, sx - ui(4), 0, sx + ui(4), h)) {
				draw_line_width(sx, 0, sx, h, 2);
				if(mouse_press(mb_left, pFOCUS)) {
					splitViewDragging = true;
					splitViewStart = sx;
					splitViewMouse = mx;
				}
			} else 
				draw_line_width(sx, 0, sx, h, 1);
			
			draw_sprite_ui_uniform(THEME.icon_active_split, 0, splitSelection? sx + ui(16) : sx - ui(16), toolbar_height + ui(16),, COLORS._main_accent);
			
			if(mouse_on_preview && mouse_press(mb_left, pFOCUS)) {
				if(point_in_rectangle(mx, my, 0, 0, sx, h))
					splitSelection = 0;
				else if(point_in_rectangle(mx, my, sx, 0, w, h))
					splitSelection = 1;
			}
		} else {
			var sy = h * splitPosition;
			
			if(mouse_on_preview && point_in_rectangle(mx, my, 0, sy - ui(4), w, sy + ui(4))) {
				draw_line_width(0, sy, w, sy, 2);
				if(mouse_press(mb_left, pFOCUS)) {
					splitViewDragging = true;
					splitViewStart = sy;
					splitViewMouse = my;
				}
			} else
				draw_line_width(0, sy, w, sy, 1);
			draw_sprite_ui_uniform(THEME.icon_active_split, 0, ui(16), splitSelection? sy + ui(16) : sy - ui(16),, COLORS._main_accent);
			
			if(mouse_on_preview && mouse_press(mb_left, pFOCUS)) {
				if(point_in_rectangle(mx, my, 0, 0, w, sy))
					splitSelection = 0;
				else if(point_in_rectangle(mx, my, 0, sy, w, h))
					splitSelection = 1;
			}
		}
	} #endregion
	
	function drawContent(panel) { #region					>>>>>>>>>>>>>>>>>>>> MAIN DRAW <<<<<<<<<<<<<<<<<<<<
		mouse_on_preview = pHOVER && point_in_rectangle(mx, my, 0, toolbar_height, w, h - toolbar_height);
			
		var _prev_node   = getNodePreview();
		
		d3_active = _prev_node != noone && _prev_node.is_3D;
		
		draw_clear(bg_color);
		if(canvas_bg == -1 && canvas_s >= 0.1) 
			draw_sprite_tiled_ext(s_transparent, 0, canvas_x, canvas_y, canvas_s, canvas_s, COLORS.panel_preview_transparent, 1);
		else
			draw_clear(canvas_bg);
		draw_set_color(COLORS._main_icon_dark);
		draw_line_width(canvas_x, 0, canvas_x, h, 1);
		draw_line_width(0, canvas_y, w, canvas_y, 1);
		
		bg_color = lerp_color(bg_color, d3_active? COLORS.panel_3d_bg : COLORS.panel_bg_clear, 0.3);
		title = __txt("Preview");
		
		getPreviewData();
		
		if(_prev_node) {
			if(d3_active) {
				dragCanvas3D();
				draw3D();
			} else {
				dragCanvas();
				drawNodePreview();
			}
		} else dragCanvas();
		
		drawPreviewOverlay();
		
		var inspect_node = PANEL_INSPECTOR.getInspecting();
		
		var tool = noone;
		if(inspect_node) {
			tool = inspect_node.getTool();
			if(tool) drawNodeTools(pFOCUS, tool);
		} else 
			tool_current = noone;
		
		if(do_fullView) {
			do_fullView = false;
			fullView();
		}
		
		if(mouse_on_preview && mouse_press(mb_right, pFOCUS) && !key_mod_press(SHIFT)) {
			menuCall("preview_context_menu",,, [ 
				menuItem(__txtx("panel_graph_preview_window", "Send to preview window"), function() { create_preview_window(getNodePreview()); }, noone, ["Preview", "Preview window"]), 
				-1,
				menuItem(__txtx("panel_preview_save", "Save current preview as") + "...", function() { saveCurrentFrame(); }), 
				menuItem(__txtx("panel_preview_save_all", "Save all current previews as") + "...", function() { saveAllCurrentFrames(); }), 
				-1,
				menuItem(__txtx("panel_preview_copy_image", "Copy image"), function() { copyCurrentFrame(); }, THEME.copy), 
				menuItem(__txtx("panel_preview_copy_color", "Copy color") + " [" + string(sample_color) + "]", function() { clipboard_set_text(sample_color); }), 
				menuItem(__txtx("panel_preview_copy_hex", "Copy hex") + " [" + string(color_get_hex(sample_color)) + "]", function() { clipboard_set_text(color_get_hex(sample_color)); }), 
			],, getNodePreview());
		}
		
		if(!d3_active) drawSplitView();
		drawToolBar(tool);
	} #endregion
	
	function copyCurrentFrame() { #region
		var prevS = getNodePreviewSurface();
		if(!is_surface(prevS)) return;
		
		var buff = buffer_create(surface_get_width_safe(prevS) * surface_get_height_safe(prevS) * 4, buffer_fixed, 1);
		var s = surface_create(surface_get_width_safe(prevS), surface_get_height_safe(prevS));
		
		surface_set_target(s);
			shader_set(sh_BGR);
			draw_surface(prevS, 0, 0);
			shader_reset();
		surface_reset_target();
		
		buffer_get_surface(buff, s, 0);
		surface_free(s);
		
		clipboard_set_bitmap(buffer_get_address(buff), surface_get_width_safe(prevS), surface_get_height_safe(prevS));
	} #endregion
	
	function saveCurrentFrame() { #region
		var prevS = getNodePreviewSurface();
		if(!is_surface(prevS)) return;
		
		var path = get_save_filename(".png", "export"); 
		key_release();
		if(path == "") return;
		if(filename_ext(path) != ".png") path += ".png";
		
		surface_save_safe(prevS, path);
	} #endregion
	
	function saveAllCurrentFrames() { #region
		var path = get_save_filename(".png", "export"); 
		key_release();
		if(path == "") return;
		
		var ext = ".png";
		var name = string_replace_all(path, ext, "");
		var ind  = 0;
		
		var pseq = getNodePreviewSequence();
		for(var i = 0; i < array_length(pseq); i++) {
			var prev   = pseq[i];
			if(!is_surface(prev)) continue;
			var _name = name + string(ind) + ext;
			surface_save_safe(prev, _name);
			ind++;
		}
	} #endregion
}