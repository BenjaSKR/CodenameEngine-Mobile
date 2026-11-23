package funkin.backend.utils;

import openfl.utils.Assets;
import openfl.media.Sound;

#if (sys && ALLOW_MULTITHREADING)
import sys.thread.Thread;
import sys.thread.Lock;
#end

/**
 * Decodifica varios audios (.ogg) a la vez en hilos separados y los deja en la cache de Assets.
 * El tiempo total pasa de ser la SUMA de todas las pistas a ser el de la pista mas larga.
 */
class AudioPreloader {
	public static function preload(ids:Array<String>):Void {
		#if (sys && ALLOW_MULTITHREADING)
		var todo:Array<String> = [];
		for (id in ids) {
			if (id == null || todo.contains(id)) continue;
			if (Assets.cache.enabled && Assets.cache.hasSound(id)) continue;
			if (!Assets.exists(id)) continue;
			todo.push(id);
		}
		if (todo.length < 2) return; // con una sola pista no hay nada que paralelizar

		var results:Array<Sound> = [for (_ in todo) null];
		var lock = new Lock();
		for (i in 0...todo.length) {
			Thread.create(function() {
				try {
					results[i] = Assets.getSound(todo[i], false);
				} catch (e:Dynamic) {
					results[i] = null;
				}
				lock.release();
			});
		}
		for (_ in todo) lock.wait();

		// la cache se escribe solo desde el hilo principal
		for (i in 0...todo.length)
			if (results[i] != null && Assets.cache.enabled)
				Assets.cache.setSound(todo[i], results[i]);
		#end
	}
}
