package funkin.backend.utils;

import funkin.game.Note;
import funkin.game.StrumLine;

/**
 * Diagnostico: anota en "inputlog.txt" cada toque (TAP) en un carril del jugador y cada miss (MISS),
 * con el estado de la nota mas cercana, para ver por que una nota "se va" aunque se toque a tiempo.
 */
class InputLog {
	static var lines:Array<String> = [];
	static var dirty:Bool = false;

	public static function reset(title:String):Void {
		#if sys
		lines = ['=== $title ==='];
		save();
		#end
	}

	static inline function r(v:Float):String
		return Std.string(Math.round(v * 10) / 10);

	public static function tap(strumLine:StrumLine, lane:Int, songPos:Float):Void {
		#if sys
		if (lines.length > 700) return;
		var best:Note = null;
		var bestDist:Float = 1e9;
		var count = 0;
		strumLine.notes.forEachAlive(function(n:Note) {
			if (n.strumID != lane || n.isSustainNote || n.wasGoodHit) return;
			var d = Math.abs(n.strumTime - songPos);
			if (d < 400) count++;
			if (d < bestDist) { bestDist = d; best = n; }
		});
		if (best == null) {
			lines.push('TAP carril $lane @${r(songPos)}ms: sin nota cercana');
		} else {
			lines.push('TAP carril $lane @${r(songPos)}ms: nota t=${r(best.strumTime)} dif=${r(best.strumTime - songPos)}ms canBeHit=${best.canBeHit} tooLate=${best.tooLate} avoid=${best.avoid} tipo=${best.noteType} notasEn400ms=$count');
		}
		save();
		#end
	}

	public static function miss(songPos:Float, n:Note):Void {
		#if sys
		if (lines.length > 700 || n == null) return;
		lines.push('MISS carril ${n.strumID} @${r(songPos)}ms: nota t=${r(n.strumTime)} dif=${r(n.strumTime - songPos)}ms sustain=${n.isSustainNote} canBeHit=${n.canBeHit} wasGoodHit=${n.wasGoodHit} avoid=${n.avoid} tipo=${n.noteType}');
		save();
		#end
	}

	static function save():Void {
		#if sys
		try {
			sys.io.File.saveContent(Sys.getCwd() + "inputlog.txt", lines.join("\n") + "\n");
		} catch (e:Dynamic) {}
		#end
	}
}
