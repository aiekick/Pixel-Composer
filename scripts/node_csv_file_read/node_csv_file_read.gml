function Node_create_CSV_File_Read(_x, _y, _group = noone) { #region
	var path = "";
	if(!LOADING && !APPENDING && !CLONING) {
		path = get_open_filename(".csv", "");
		key_release();
		if(path == "") return noone;
	}
	
	var node = new Node_CSV_File_Read(_x, _y, _group);
	node.inputs[| 0].setValue(path);
	node.doUpdate();
	
	return node;
} #endregion

function Node_create_CSV_File_Read_path(_x, _y, path) { #region
	if(!file_exists(path)) return noone;
	
	var node = new Node_CSV_File_Read(_x, _y, PANEL_GRAPH.getCurrentContext());
	node.inputs[| 0].setValue(path);
	node.doUpdate();
	
	return node;	
} #endregion

function Node_CSV_File_Read(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "CSV File In";
	color = COLORS.node_blend_input;
	previewable = false;
	
	w = 128;
	
	inputs[| 0]  = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.path, "")
		.setDisplay(VALUE_DISPLAY.path_load, { filter: "*.csv" })
		.rejectArray();
		
	inputs[| 1]  = nodeValue("Convert to number", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false)
		.rejectArray();
	
	outputs[| 0] = nodeValue("Content", self, JUNCTION_CONNECT.output, VALUE_TYPE.text, "");
	
	outputs[| 1] = nodeValue("Path", self, JUNCTION_CONNECT.output, VALUE_TYPE.path, "")
		.setVisible(true, true);
	
	content = "";
	path_current = "";
	
	first_update = false;
	
	on_drop_file = function(path) { #region
		if(updatePaths(path)) {
			doUpdate();
			return true;
		}
		
		return false;
	} #endregion
	
	function updatePaths(path) { #region
		path = try_get_path(path);
		if(path == -1) return false;
		
		var ext = string_lower(filename_ext(path));
		var _name = string_replace(filename_name(path), filename_ext(path), "");
		
		if(ext != ".csv") return false;
			
		outputs[| 1].setValue(path);
		
		content = file_text_read_all_lines(path);
		
		var convert = getInputData(1);
		outputs[| 0].setType(convert? VALUE_TYPE.float : VALUE_TYPE.text);
		if(convert) {
			for( var i = 0, n = array_length(content); i < n; i++ ) {
				var c = content[i];
				
				if(is_array(c)) {
					for( var j = 0; j < array_length(c); j++ )
						content[i][j] = toNumber(c[j]);
				} else 
					content[i] = toNumber(c);
			}
		}
		
		if(path_current == "") 
			first_update = true;
		path_current = path;
				
		return true;
	} #endregion
	
	insp1UpdateTooltip  = __txt("Refresh");
	insp1UpdateIcon     = [ THEME.refresh, 1, COLORS._main_value_positive ];
	
	static onInspector1Update = function() { #region
		var path = getInputData(0);
		if(path == "") return;
		updatePaths(path);
		update();
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { #region
		var path = getInputData(0);
		if(path == "") return;
		if(path_current != path) updatePaths(path);
		
		outputs[| 0].setValue(content);
	} #endregion
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		var bbox = drawGetBbox(xx, yy, _s);
		
		var str = filename_name(path_current);
		draw_set_text(f_sdf, fa_center, fa_center, COLORS._main_text);
		var ss	= string_scale(str, bbox.w, bbox.h);
		draw_text_transformed(bbox.xc, bbox.yc, str, ss, ss, 0);
	} #endregion
}