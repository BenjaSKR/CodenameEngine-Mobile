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

	static var accs:Map<String, Float> = [];
	static var counts:Map<String, Int> = [];

	/** Suma el tiempo transcurrido desde `t` (Sys.time()) a la etiqueta; devuelve el tiempo actual para encadenar. */
	public static inline function acc(label:String, t:Float):Float {
		#if sys
		var now = Sys.time();
		accs.set(label, (accs.exists(label) ? accs.get(label) : 0) + (now - t));
		counts.set(label, (counts.exists(label) ? counts.get(label) : 0) + 1);
		return now;
		#else
		return 0;
		#end
	}

	public static inline function now():Float {
		#if sys
		return Sys.time();
		#else
		return 0;
		#end
	}

	/** Escribe los acumulados en el archivo con un titulo. */
	public static function flushAcc(title:String):Void {
		#if sys
		lines.push("--- " + title + " ---");
		for (k in accs.keys()) lines.push("  " + k + ": " + round(accs.get(k)) + "s en " + counts.get(k) + " llamadas");
		accs = [];
		counts = [];
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
