package com.phonegap.bossbolo.plugin.socket;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

public class MyZip {
	public static final byte[] zip(String str) {
		if (str == null) return null;
		byte[] compressed = str.getBytes();
		return zip(compressed);
	}
	/**
	* 浣跨敤zip杩涜鍘嬬缉
	* @param str 鍘嬬缉鍓嶇殑鏂囨湰
	* @return 杩斿洖鍘嬬缉鍚庣殑鏂囨湰
	*/
	public static final byte[] zip(byte[] compressed) {
		ByteArrayOutputStream out = null;
		ZipOutputStream zout = null;
		try {
			out = new ByteArrayOutputStream();
			zout = new ZipOutputStream(out);
			zout.putNextEntry(new ZipEntry("0"));
			zout.write(compressed);
			zout.closeEntry();
			compressed = out.toByteArray();
		} 
		catch (Exception e) {
			compressed = null;
			e.printStackTrace();
		} 
		finally {
			if (zout != null) {
				try {
					zout.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
			if (out != null) {
				try {
					out.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
		return compressed;
	}
	
	/**
	* 浣跨敤zip杩涜瑙ｅ帇缂�
	* @param compressed 鍘嬬缉鍚庣殑鏂囨湰
	* @return 瑙ｅ帇鍚庣殑瀛楃涓�
	*/
	public static final String unzip(byte[] compressed) {
		if (compressed == null) {
			return null;
		}
		ByteArrayOutputStream out = null;
		ByteArrayInputStream in = null;
		ZipInputStream zin = null;
		String str = null;
		try {
			
			out = new ByteArrayOutputStream();
			in = new ByteArrayInputStream(compressed);
			zin = new ZipInputStream(in);
			zin.getNextEntry();
			byte[] buffer = new byte[1024];
			int offset = -1;
			while ((offset = zin.read(buffer)) != -1) {
				out.write(buffer, 0, offset);
			}
			str = out.toString();
		} 
		catch (Exception e) {
			str = null;
			e.printStackTrace();
		} 
		finally {
			if (zin != null) {
				try {
					zin.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
			if (in != null) {
				try {
					in.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
			if (out != null) {
				try {
					out.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
		return str;
	}
	
	public static final byte[] gzip(String str) {
		byte[] compressed = str.getBytes();
		return gzip(compressed);
	}
	
	/**
	* 浣跨敤gzip杩涜鍘嬬缉
	* @param str 鍘嬬缉鍓嶇殑鏂囨湰
	* @return 杩斿洖鍘嬬缉鍚庣殑鏂囨湰
	*/
	public static final byte[] gzip(byte[] compressed) {
		ByteArrayOutputStream out = null;
		GZIPOutputStream zout = null;
		try {
			out = new ByteArrayOutputStream();
			zout = new GZIPOutputStream(out);			
			zout.write(compressed);
			zout.finish();  
			zout.flush();
			compressed = out.toByteArray();
		} 
		catch (Exception e) {
			compressed = null;
			e.printStackTrace();
		} 
		finally {
			if (zout != null) {
				try {
					zout.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
			if (out != null) {
				try {
					out.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
		return compressed;
	}

	/**
	* 浣跨敤gzip杩涜瑙ｅ帇缂�
	* @param compressed 鍘嬬缉鍚庣殑鏂囨湰
	* @return 瑙ｅ帇鍚庣殑瀛楃涓�
	*/
	public static final String ungzip(byte[] compressed) {
		if (compressed == null) {
			return null;
		}
		ByteArrayOutputStream out = null;
		ByteArrayInputStream in = null;
		GZIPInputStream zin = null;
		String str = null;
		try {
			
			out = new ByteArrayOutputStream();
			in = new ByteArrayInputStream(compressed);
			zin = new GZIPInputStream(in);			
			byte[] buffer = new byte[1024];
			int offset = -1;
			while ((offset = zin.read(buffer)) != -1) {
				out.write(buffer, 0, offset);
			}
			str = out.toString();
		} 
		catch (Exception e) {
			str = null;
			e.printStackTrace();
		} 
		finally {
			if (zin != null) {
				try {
					zin.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
			if (in != null) {
				try {
					in.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
			if (out != null) {
				try {
					out.close();
				} 
				catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
		return str;
	}
}
