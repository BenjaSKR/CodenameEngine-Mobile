package funkin.backend.utils;

/**
 * Herramienta de diagnostico: guarda cuanto tarda cada etapa de la carga en "loadtimes.txt"
 * (en la misma carpeta donde estan tus mods/ y assets/).
 */
class LoadTimer {
	static var t0:Float = 0;
	static var last:Float = 0;
	static var lines:Array<String> = [];

	public static function start(label:String):Void {
		#if sys
		t0 = last = Sys.time();
		lines = ['=== $label ==='];
		save();
		#end
	}

	public static function mark(label:String):Void {
		#if sys
		var now = Sys.time();
		lines.push(label + ": +" + round(now - last) + "s (total " + round(now - t0) + "s)");
		last = now;
		save();
		#end
	}

	static function round(v:Float):String
		return Std.string(Math.round(v * 100) / 100);

	static function save():Void {
		#if sys
		try {
			sys.io.File.saveContent(Sys.getCwd() + "loadtimes.txt", lines.join("\n") + "\n");
		} catch (e:Dynamic) {}
		#end
	}
}
