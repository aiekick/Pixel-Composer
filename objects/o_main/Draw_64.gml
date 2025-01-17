/// @description init
draw_clear(COLORS.bg);

#region gameframe
	if(OS == os_windows && gameframe_is_minimized()) {
		//gameframe_update();
		exit;
	} else if(OS == os_macosx) {
		mac_window_step();
	}
#endregion

#region widget scroll
	if(!WIDGET_TAB_BLOCK) {
		if(keyboard_check_pressed(vk_tab) && key_mod_press(SHIFT))
			widget_previous();
		else if(keyboard_check_pressed(vk_tab))
			widget_next();
	
		if(keyboard_check_pressed(vk_enter))
			widget_trigger();
		
		if(keyboard_check_pressed(vk_escape))
			widget_clear();
	}
	
	WIDGET_TAB_BLOCK = false;
#endregion

#region register UI element
	WIDGET_ACTIVE = [];
#endregion

#region panels
	if(PANEL_MAIN == 0) resetPanel();
	
	var surf = surface_get_target();
	try {
		PANEL_MAIN.draw();
	} catch(e) { 
		while(surface_get_target() != surf)
			surface_reset_target();
		
		noti_warning(exception_print(e));
	}
	
	panelDraw();
	
	gameframe_update();
#endregion

#region notes
	for( var i = 0, n = array_length(PROJECT.notes); i < n; i++ )
		PROJECT.notes[i].draw();
#endregion

#region window
	var pd = gameframe_resize_padding;
	
	if(mouse_mx > 0 && mouse_mx < pd && mouse_my > 0 && mouse_my < WIN_H)
		CURSOR = cr_size_we;
	if(mouse_mx > WIN_W - pd && mouse_mx < WIN_W && mouse_my > 0 && mouse_my < WIN_H)
		CURSOR = cr_size_we;
		
	if(mouse_mx > 0 && mouse_mx < WIN_W && mouse_my > 0 && mouse_my < pd)
		CURSOR = cr_size_ns;
	if(mouse_mx > 0 && mouse_mx < WIN_W && mouse_my > WIN_H - pd && mouse_my < WIN_H)
		CURSOR = cr_size_ns;
	
	if(mouse_mx > 0 && mouse_mx < pd && mouse_my > 0 && mouse_my < pd)
		CURSOR = cr_size_nwse;
	if(mouse_mx > WIN_W - pd && mouse_mx < WIN_W && mouse_my > WIN_H - pd && mouse_my < WIN_H)
		CURSOR = cr_size_nwse;
	
	if(mouse_mx > 0 && mouse_mx < pd && mouse_my > WIN_H - pd && mouse_my < WIN_H)
		CURSOR = cr_size_nesw;
	if(mouse_mx > WIN_W - pd && mouse_mx < WIN_W && mouse_my > 0 && mouse_my < pd)
		CURSOR = cr_size_nesw;
#endregion