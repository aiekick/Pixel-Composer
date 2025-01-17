function Node_Json_File_Write(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "JSON File Out";
	color = COLORS.node_blend_input;
	previewable = false;
	
	w = 128;
	
	inputs[| 0]  = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.path, "")
		.setDisplay(VALUE_DISPLAY.path_save, { filter: "*.json" })
		.rejectArray();
		
	inputs[| 1]  = nodeValue("Struct", self, JUNCTION_CONNECT.input, VALUE_TYPE.struct, {})
		.setVisible(true, true);
	
	static createNewInput = function() {
		var index = ds_list_size(inputs);
		inputs[| index + 0] = nodeValue("Key", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "" );
		
		inputs[| index + 1] = nodeValue("value", self, JUNCTION_CONNECT.input, VALUE_TYPE.any, 0 )
			.setVisible(false, false);
		
		array_push(input_display_list, index + 0);
		array_push(input_display_list, index + 1);
	}
	
	input_display_list = [ 0, 1, 
		["Inputs", false],
	]

	setIsDynamicInput(3);
	
	if(!LOADING && !APPENDING) createNewInput();
	
	static refreshDynamicInput = function() {
		var _in = ds_list_create();
		
		for( var i = 0; i < input_fix_len; i++ )
			ds_list_add(_in, inputs[| i]);
		
		array_resize(input_display_list, input_display_len);
		
		if(inputs[| 1].value_from != noone) {
			ds_list_destroy(inputs);
			inputs = _in;
			return;
		}
		
		for( var i = input_fix_len; i < ds_list_size(inputs); i += data_length ) {
			if(getInputData(i) != "") {
				ds_list_add(_in, inputs[| i + 0]);
				ds_list_add(_in, inputs[| i + 1].setVisible(false, true));
				
				array_push(input_display_list, i + 0);
				array_push(input_display_list, i + 1);
			} else {
				delete inputs[| i + 0];
				delete inputs[| i + 1];
			}
		}
		
		for( var i = 0; i < ds_list_size(_in); i++ )
			_in[| i].index = i;
		
		ds_list_destroy(inputs);
		inputs = _in;
		
		createNewInput();
	}
	
	static onValueUpdate = function(index = 0) {
		if(index < input_fix_len) return;
		if(LOADING || APPENDING) return;
		
		if(safe_mod(index - input_fix_len, data_length) == 0) { //Variable name
			inputs[| index + 1].name = getInputData(index) + " value";
		}
		
		refreshDynamicInput();
	}
	
	static writeFile = function() {
		var path = getInputData(0);
		if(path == "") return;
		if(filename_ext(path) != ".json")
			path += ".json";
		
		var cont = {};
		
		if(inputs[| 1].isLeaf()) {
			for( var i = input_fix_len; i < ds_list_size(inputs) - data_length; i += data_length ) {
				var _key = getInputData(i + 0);
				var _val = getInputData(i + 1);
			
				inputs[| i + 1].setType(inputs[| i + 1].value_from? inputs[| i + 1].value_from.type : VALUE_TYPE.any);
			
				variable_struct_set(cont, _key, _val);
			}
		} else 
			cont = getInputData(1);
		
		json_save_struct(path, cont);
	}
	
	static step = function() { 
		for(var i = input_fix_len; i < ds_list_size(inputs) - data_length; i += data_length) {
			var inp  = inputs[| i + 1];
			var typ  = inp.isLeaf()? VALUE_TYPE.any : inp.value_from.type;
			inp.setType(typ);
		}
	}
	
	static update = function(frame = CURRENT_FRAME) { writeFile(); }
	static onInspector1Update = function() { writeFile(); }
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		
		var str = filename_name(getInputData(0));
		if(filename_ext(str) != ".json")
			str += ".json";
			
		draw_set_text(f_sdf, fa_center, fa_center, COLORS._main_text);
		var ss	= string_scale(str, bbox.w, bbox.h);
		draw_text_transformed(bbox.xc, bbox.yc, str, ss, ss, 0);
	}
	
	static doApplyDeserialize = function() {
		refreshDynamicInput();
	}
}