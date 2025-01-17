function Node_Shell(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name		= "Execute Shell";
	
	w = 96;
	min_h = 32 + 24 * 1;
	draw_padding = 8;
	
	inputs[| 0] = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "");
	
	inputs[| 1] = nodeValue("Script", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "");
	
	insp1UpdateTooltip   = "Run";
	insp1UpdateIcon      = [ THEME.sequence_control, 1, COLORS._main_value_positive ];
	
	trusted = false;
	
	static onValueUpdate = function() {
		trusted = false;
	}
	
	static onInspector1Update = function() { update(); }
	
	static update = function() { 
		var _pro = getInputData(0);
		var _scr = getInputData(1);
		if(_pro == "" || _scr == "") return;
		
		if(trusted) {
			shell_execute_async(_pro, _scr);
		} else {
			var dia = dialogCall(o_dialog_run_shell);
			dia.setData(self, _pro, _scr);
		}
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		var txt  = getInputData(0);
		
		draw_set_text(f_p0, fa_center, fa_center, COLORS._main_text);
		draw_text_bbox(bbox, txt);
	}
}