package funkin.backend.utils;

import flixel.FlxG;

/**
 * Medidor de carga. NO cambia como carga nada, solo mide y escribe "assettimes.txt"
 * (en /sdcard/.CodenameEngine/). Cada vez que se entra a un state (menu, PlayState...)
 * agrega una seccion con cuanto tardo cada tipo de archivo.
 */
class AssetTimer {
	static var inited:Bool = false;
	static var depth:Int = 0;
	static var stateStart:Float = 0;
	static var accs:Map<String, Float> = [];
	static var counts:Map<String, Int> = [];
	static var slow:Array<{kind:String, id:String, t:Float, info:String}> = [];
	static var pixels:Float = 0;
	static var lines:Array<String> = [];

	public static inline function now():Float
		return Sys.time();

	/** Llamar al terminar una operacion medida. `t0` = now() de cuando empezo. */
	public static function add(kind:String, id:String, t0:Float, ?info:String):Void {
		init();
		var dt = Sys.time() - t0;
		accs.set(kind, (accs.exists(kind) ? accs.get(kind) : 0) + dt);
		counts.set(kind, (counts.exists(kind) ? counts.get(kind) : 0) + 1);
		if (dt >= 0.02 && slow.length < 20000) slow.push({kind: kind, id: id, t: dt, info: info == null ? "" : info});
	}

	public static function addImageSize(w:Int, h:Int):Void
		pixels += w * h;

	/** Evita contar dos veces las llamadas anidadas (getImage llama a exists). */
	public static inline function enter():Bool return depth++ == 0;
	public static inline function leave():Void depth--;

	static function init():Void {
		if (inited) return;
		inited = true;
		stateStart = Sys.time();
		FlxG.signals.preStateSwitch.add(function() {
			reset();
			stateStart = Sys.time();
		});
		FlxG.signals.postStateSwitch.add(onPost);
	}

	static function reset():Void {
		accs = [];
		counts = [];
		slow = [];
		pixels = 0;
		depth = 0;
	}

	static function r(v:Float):String
		return Std.string(Math.round(v * 100) / 100);

	static function onPost():Void {
		var total = Sys.time() - stateStart;
		var name = Type.getClassName(Type.getClass(FlxG.state));
		try {
			if (FlxG.state is funkin.game.PlayState && funkin.game.PlayState.SONG != null && funkin.game.PlayState.SONG.meta != null)
				name += " (" + funkin.game.PlayState.SONG.meta.name + ")";
		} catch (e:Dynamic) {}

		lines.push("");
		lines.push("=== " + name + " ===");
		lines.push("Tiempo total del create(): " + r(total) + " s");

		var measured = 0.0;
		var kinds = [for (k in accs.keys()) k];
		kinds.sort((a, b) -> accs.get(b) > accs.get(a) ? 1 : -1);
		for (k in kinds) {
			var v = accs.get(k);
			if (k != "primer draw") measured += v;
			lines.push("  " + k + ": " + r(v) + " s en " + counts.get(k) + " llamadas");
		}
		lines.push("  (tiempo medido en archivos: " + r(measured) + " s)");
		lines.push("  RESTO (scripts, XML/JSON ya leidos, crear sprites, logica del juego): " + r(total - measured) + " s");
		if (pixels > 0)
			lines.push("  Imagenes decodificadas en este state: ~" + Math.round(pixels * 4 / 1048576) + " MB de pixeles (RGBA)");

		slow.sort((a, b) -> a.t < b.t ? 1 : -1);
		lines.push("  --- 40 archivos mas lentos (>= 0.02 s) ---");
		for (i in 0...Std.int(Math.min(40, slow.length))) {
			var s = slow[i];
			lines.push("  " + r(s.t) + " s  [" + s.kind + "] " + s.id + (s.info != "" ? "  " + s.info : ""));
		}
		save();
	}

	/** Lo llama FunkinGame despues del draw() que sube todo a la GPU. */
	public static function drawDone(t0:Float):Void {
		if (!inited) return;
		lines.push("  primer draw (subida de texturas a la GPU, shaders): " + r(Sys.time() - t0) + " s");
		save();
	}

	static function save():Void {
		try {
			sys.io.File.saveContent(Sys.getCwd() + "assettimes.txt", lines.join("\n") + "\n");
		} catch (e:Dynamic) {}
	}
}
