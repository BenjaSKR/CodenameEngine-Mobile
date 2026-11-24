package funkin.backend.utils;

/**
 * Diagnostico: anota en "hitches.txt" (carpeta .CodenameEngine) cada vez que un fotograma tarda mas de lo normal
 * durante una cancion, con la posicion de la cancion y el step, para ver si coincide con notas que "se van".
 */
class HitchLog {
	static var lastTime:Float = 0;
	static var lines:Array<String> = [];
	static var started:Bool = false;
	public static var thresholdMs:Float = 70;

	public static function reset(title:String):Void {
		#if sys
		lines = ['=== $title (umbral ${thresholdMs} ms) ==='];
		lastTime = Sys.time();
		started = true;
		save();
		#end
	}

	public static function tick(songPos:Float, step:Int):Void {
		#if sys
		if (!started) return;
		var now = Sys.time();
		var dt = (now - lastTime) * 1000;
		lastTime = now;
		if (dt > thresholdMs && lines.length < 400) {
			lines.push('cancion ' + Math.round(songPos) + ' ms (' + Math.round(songPos / 100) / 10 + ' s), step ' + step + ': fotograma de ' + Math.round(dt) + ' ms');
			save();
		}
		#end
	}

	static function save():Void {
		#if sys
		try {
			sys.io.File.saveContent(Sys.getCwd() + "hitches.txt", lines.join("\n") + "\n");
		} catch (e:Dynamic) {}
		#end
	}
}
