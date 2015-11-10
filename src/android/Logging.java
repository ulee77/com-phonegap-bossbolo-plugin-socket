package com.phonegap.bossbolo.plugin.socket;

import java.util.logging.Level;
import java.util.logging.Logger;

public class Logging {
	public static void Error(String klass, String message, Throwable t) {
		Logger.getLogger(klass).log(Level.SEVERE, message, t);
	}
}
