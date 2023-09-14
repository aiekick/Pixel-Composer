function Node_create_WAV_File_Read(_x, _y, _group = noone) { #region
	var path = "";
	if(!LOADING && !APPENDING && !CLONING) {
		path = get_open_filename(".wav", "");
		key_release();
		if(path == "") return noone;
	}
	
	var node = new Node_WAV_File_Read(_x, _y, _group);
	node.inputs[| 0].setValue(path);
	node.doUpdate();
	
	return node;
} #endregion

function Node_create_WAV_File_Read_path(_x, _y, path) { #region
	if(!file_exists(path)) return noone;
	
	var node = new Node_WAV_File_Read(_x, _y, PANEL_GRAPH.getCurrentContext());
	node.inputs[| 0].setValue(path);
	node.doUpdate();
	
	return node;	
} #endregion

function Node_WAV_File_Read(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "WAV File In";
	color = COLORS.node_blend_input;
	previewable = false;
	
	w = 128;
	h = 128;
	min_h = h;
	
	inputs[| 0]  = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.path, "")
		.setDisplay(VALUE_DISPLAY.path_load, ["*.wav", ""])
		.rejectArray();
	
	inputs[| 1]  = nodeValue("Sync lenght", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.button, [ function() { 
			if(content == noone) return;
			var frm = max(1, ceil(content.duration * PROJECT.animator.framerate));
			PROJECT.animator.frames_total = frm;
		}, "Sync"])
		.rejectArray();
		
	outputs[| 0] = nodeValue("Data", self, JUNCTION_CONNECT.output, VALUE_TYPE.float, [])
		.setArrayDepth(1);
	
	outputs[| 1] = nodeValue("Path", self, JUNCTION_CONNECT.output, VALUE_TYPE.path, "");
	
	outputs[| 2] = nodeValue("Sample rate", self, JUNCTION_CONNECT.output, VALUE_TYPE.integer, 44100)
		.setVisible(false);
	
	outputs[| 3] = nodeValue("Channels", self, JUNCTION_CONNECT.output, VALUE_TYPE.integer, 2)
		.setVisible(false);
	
	outputs[| 4] = nodeValue("Duration (s)", self, JUNCTION_CONNECT.output, VALUE_TYPE.float, 0)
		.setVisible(false);
	
	outputs[| 5] = nodeValue("Loudness", self, JUNCTION_CONNECT.output, VALUE_TYPE.float, 0)
		.setVisible(false);
	
	content = noone;
	path_current = "";
	
	first_update = false;
	
	output_display_list = [ 0, 1, 2, 3, 4, 5 ];
	audio_surface = -1;
	preview_audio = -1;
	preview_id = noone;
	
	wav_file_reading = false;
	wav_file_prg = 0;
	wav_file_lim = 1;
	
	#region attribute
		attributes.preview_shift = 0;
		attributes.preview_gain = 0.5;
	
		array_push(attributeEditors, "Audio Preview");
	
		array_push(attributeEditors, ["Gain", function() { return attributes.preview_gain; }, 
			new textBox(TEXTBOX_INPUT.number, function(val) { 
				attributes.preview_gain = val; 
			})]);
		
		array_push(attributeEditors, ["Shift", function() { return attributes.preview_shift; }, 
			new textBox(TEXTBOX_INPUT.number, function(val) { 
				attributes.preview_shift = val; 
			})]);
	#endregion
		
	on_dragdrop_file = function(path) { #region
		if(updatePaths(path)) {
			doUpdate();
			return true;
		}
		
		return false;
	} #endregion
	
	function checkPreview(force = false) { #region
		if(content == noone) return;
		if(!force && is_surface(audio_surface)) return;
		
		print("-- Creating preview surface...");
		
		var ch  = content.channels;
		if(ch == 0) return;
		
		if(!struct_has(content, "sound"))	return;
		if(array_length(content.sound) < 1) return;
		
		var len = array_length(content.sound[0]);
		if(len == 0) return;
		
		var spc = min(320, len);
		var stp = len / spc;
		var ww  = h;
		
		audio_surface = surface_verify(audio_surface, 320, ww);
		surface_set_target(audio_surface);
			draw_clear_alpha(c_white, 0);
			draw_set_color(c_white);
			
			var ox, oy, nx, ny;
			
			for( var i = 0; i < len; i += stp ) {
				nx = i / len * 320;
				ny = ww / 2 + content.sound[0][i] * ww;
				
				if(i) draw_line_width(ox, oy, nx, ny, 4);
				
				ox = nx;
				oy = ny;
			}
		surface_reset_target();
	} #endregion
	
	function updatePaths(path) { #region
		path = try_get_path(path);
		if(path == -1) return false;
		
		if(path_current == "") 
			first_update = true;
		path_current = path;
		
		var ext = string_lower(filename_ext(path));
		var _name = string_replace(filename_name(path), filename_ext(path), "");
		
		if(ext != ".wav") return false;
			
		outputs[| 1].setValue(path);
		
		printIf(global.FLAG.wav_import, "-- Reading file...");
		
		content = file_read_wav(path);
		return true;
	} #endregion
	
	function readSoundComplete() { #region
		outputs[| 0].setValue(content.sound);
		outputs[| 2].setValue(content.sample);
		outputs[| 3].setValue(content.channels);
		outputs[| 4].setValue(content.duration);
		
		printIf(global.FLAG.wav_import, "-- Creating preview buffer...");
		
		var frm = ceil(content.duration * PROJECT.animator.framerate);
		inputs[| 1].editWidget.text = $"Sync ({frm} frames)";
		
		var bufferId = buffer_create(content.packet * 2, buffer_fixed, 1);
		buffer_seek(bufferId, buffer_seek_start, 0);
		
		var val_to_write = 1;

		for (var i = 0; i < content.packet; i++)
			buffer_write(bufferId, buffer_s16, round(content.sound[0][i] / 4 * 65535));
		
		preview_audio = audio_create_buffer_sound(bufferId, buffer_s16, content.sample, 0, content.packet * 2, audio_mono);
	} #endregion
	
	#region ++++ inspector ++++
	insp1UpdateTooltip  = __txt("Refresh");
	insp1UpdateIcon     = [ THEME.refresh, 1, COLORS._main_value_positive ];
	
	insp2UpdateTooltip  = __txtx("play_with_timeline", "Play with timeline");
	insp2UpdateIcon     = [ THEME.play_sound, 1, COLORS._main_icon_light ];
	attributes.play = true;
	
	static onInspector1Update = function() {
		var path = inputs[| 0].getValue();
		if(path == "") return;
		updatePaths(path);
		update();
	}
	
	static onInspector2Update = function() {
		attributes.play = !attributes.play;
	}
	#endregion
	
	static step = function() { #region
		if(file_read_wav_step()) {
			print("Load audio complete");
			readSoundComplete();
			checkPreview(true);
			
			UPDATE |= RENDER_TYPE.full;
		}
		
		insp2UpdateIcon[1] = attributes.play;
		insp2UpdateIcon[2] = attributes.play? COLORS._main_icon_light : COLORS._main_icon;
		if(preview_audio == -1) return;
		
		if(audio_is_playing(preview_audio) && !PROJECT.animator.is_playing)
			audio_stop_sound(preview_audio);
		
		if(!attributes.play) return;
		
		if(PROJECT.animator.is_playing) {
			var dur = PROJECT.animator.current_frame / PROJECT.animator.framerate - attributes.preview_shift;
			
			if(!audio_is_playing(preview_audio))
				preview_id = audio_play_sound(preview_audio, 1, false, attributes.preview_gain, dur);
		}
	} #endregion
	
	static update = function(frame = PROJECT.animator.current_frame) { #region
		var path = inputs[| 0].getValue();
		if(path == "") return;
		
		if(path_current != path) updatePaths(path);
		checkPreview();
		
		if(!struct_has(content, "sound"))	return;
		if(array_length(content.sound) < 1) return;
		
		var len = content.packet;
		var amp_ind = round(frame * content.sample / PROJECT.animator.framerate);
		var amp_win = content.sample / PROJECT.animator.framerate * 3;
		
		var amp_st = clamp(amp_ind - amp_win, 0, len);
		var amp_ed = clamp(amp_ind + amp_win, 0, len);
		
		var val = 0;
		if(amp_ed > amp_st) {
			for( var i = amp_st; i < amp_ed; i++ )
				val += content.sound[0][i] * content.sound[0][i];
			val /= amp_ed - amp_st;
			val  = sqrt(val);
		}
		
		var dec = 10 * log10(val);
		outputs[| 5].setValue(dec);
	} #endregion
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		if(content == noone) return;
		var bbox = drawGetBbox(xx, yy, _s);
		
		if(wav_file_reading) {
			var cx = xx + w * _s / 2;
			var cy = yy + h * _s / 2;
			var rr = min(w - 64, h - 64) * _s / 2;
			
			draw_set_color(COLORS._main_icon);
			draw_arc(cx, cy, rr, 90, 90 - 360 * wav_file_prg / content.packet, 4 * _s, 180);
			return;
		} else if(is_surface(audio_surface)) {
			var sw = surface_get_width_safe(audio_surface);
			var sh = surface_get_height_safe(audio_surface);
			
			var ss = min(bbox.w / sw, bbox.h / sh);
			draw_surface_ext_safe(audio_surface, 
				bbox.xc - sw * ss / 2, 
				bbox.yc - sh * ss / 2, 
				ss, ss,,, 0.50);
				
			var wd = (PROJECT.animator.current_frame / PROJECT.animator.framerate) / content.duration * sw;
			draw_surface_part_ext_safe(audio_surface, 0, 0, min(wd, sw), sh, 
				bbox.xc - sw * ss / 2, 
				bbox.yc - sh * ss / 2, 
				ss, ss,, attributes.play? COLORS._main_accent : c_white);
		}
		
		var str = filename_name(path_current);
		draw_set_text(f_p0, fa_center, fa_bottom, COLORS._main_text);
		var ss	= min(1, string_scale(str, bbox.w, bbox.h));
		draw_text_transformed(bbox.xc, bbox.y1, str, ss, ss, 0);
	} #endregion
	
	static drawAnimationTimeline = function(_shf, _w, _h, _s) { #region
		if(content == noone) return;
		draw_set_color(COLORS._main_icon_dark);
		draw_set_alpha(1);
		
		var _st = round(content.sample / PROJECT.animator.framerate); //sample per frame
		var _am = content.packet / _st;
		var ox, oy, nx, ny;
		
		if(!struct_has(content, "sound"))	return;
		if(array_length(content.sound) < 1) return;
		
		for( var i = 0; i <= _am; i++ ) {
			var _dat = content.sound[0][min(i * _st, content.packet - 1)];
			nx = _shf + i * _s;
			ny = _h / 2 + _dat * _h;
			
			if(i) draw_line_width(ox, oy, nx, ny, 2);
			
			ox = nx;
			oy = ny;
		}
		
		draw_set_alpha(1);
	} #endregion
}