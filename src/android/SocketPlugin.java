package com.phonegap.bossbolo.plugin.socket;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Timer;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;

import com.phonegap.bossbolo.plugin.CustomGlobal;

public class SocketPlugin extends CordovaPlugin {
	
	Map<String, SocketAdapter> socketAdapters = new HashMap<String, SocketAdapter>(); 
	private Timer timer = null;
	private Boolean opened = false;
	
	@Override
	public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {

		if (action.equals("open")) {
			this.open(args, callbackContext);
		} else if (action.equals("write")) {
			this.write(args, callbackContext);
		} else if (action.equals("shutdownWrite")) {
			this.shutdownWrite(args, callbackContext);
		} else if (action.equals("close")) {
			this.close(args, callbackContext);
		} else if (action.equals("setOptions")) {
			this.setOptions(args, callbackContext);
		} else if (action.equals("setKeepAlive")) {
			this.setKeepAlive(args, callbackContext);
		} else{
			callbackContext.error(String.format("SocketPlugin - invalid action:", action));
			return false;
		}
		return true;
	}
	
	private void open(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
		String socketKey = args.getString(0);
		String host = args.getString(1);
		int port = args.getInt(2);
		
		SocketAdapter socketAdapter = new SocketAdapterImpl();
		socketAdapter.setCloseEventHandler(new CloseEventHandler(socketKey));
		socketAdapter.setDataConsumer(new DataConsumer(socketKey));
		socketAdapter.setErrorEventHandler(new ErrorEventHandler(socketKey));
		socketAdapter.setOpenErrorEventHandler(new OpenErrorEventHandler(callbackContext));
		socketAdapter.setOpenEventHandler(new OpenEventHandler(socketKey, socketAdapter, callbackContext));
		
		socketAdapter.open(host, port);
		opened = true;
	}
	
	private void write(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
		String socketKey = args.getString(0);
		
		String data = args.getString(1);
		String mm = "["+data+"]";
		byte[] dataBuffer;
		try{
			JSONArray jSONArray = new JSONArray(mm);
			JSONObject jsonObject = jSONArray.getJSONObject(0);
			dataBuffer = MessageCodec.encode(jsonObject);
		}catch(JSONException e){
			dataBuffer = data.getBytes();
		}
		
		SocketAdapter socket = this.getSocketAdapter(socketKey);
		
		try {
			socket.write(dataBuffer);
			callbackContext.success();
		} catch (IOException e) {
			callbackContext.error(e.toString());
		}
	}

	private void shutdownWrite(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
		String socketKey = args.getString(0);
		
		SocketAdapter socket = this.getSocketAdapter(socketKey);
		
		try {
			socket.shutdownWrite();
			callbackContext.success();
		} catch (IOException e) {
			callbackContext.error(e.toString());
		}
	}
	
	private void close(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
		String socketKey = args.getString(0);
		if(timer!=null){
			timer.cancel();
			timer = null;
		}
		SocketAdapter socket = this.getSocketAdapter(socketKey);
		
		try {
			socket.close();
			callbackContext.success();
		} catch (IOException e) {
			callbackContext.error(e.toString());
		}
		opened = false;
	}
	
	private void setKeepAlive(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
		String socketKey = args.getString(0);
		
		CustomGlobal.getInstance().setHeartMessageType(args.getInt(3));
		timer = new Timer(); 
		timer.schedule( new MyTask(args, callbackContext, this), 3000, args.getInt(2));
		callbackContext.success();
	}
	
	private void setOptions(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
		
		String socketKey = args.getString(0);
		JSONObject optionsJSON = args.getJSONObject(1);
		
		SocketAdapter socket = this.getSocketAdapter(socketKey);
		
		SocketAdapterOptions options = new SocketAdapterOptions();
		options.setKeepAlive(getBooleanPropertyFromJSON(optionsJSON, "keepAlive"));
		options.setOobInline(getBooleanPropertyFromJSON(optionsJSON, "oobInline"));
		options.setReceiveBufferSize(getIntegerPropertyFromJSON(optionsJSON, "receiveBufferSize"));
		options.setSendBufferSize(getIntegerPropertyFromJSON(optionsJSON, "sendBufferSize"));
		options.setSoLinger(getIntegerPropertyFromJSON(optionsJSON, "soLinger"));
		options.setSoTimeout(getIntegerPropertyFromJSON(optionsJSON, "soTimeout"));
		options.setTrafficClass(getIntegerPropertyFromJSON(optionsJSON, "trafficClass"));
		
		try {
			socket.close();
			callbackContext.success();
		} catch (IOException e) {
			callbackContext.error(e.toString());
		}
	}
	
	private Boolean getBooleanPropertyFromJSON(JSONObject jsonObject, String propertyName) throws JSONException {
		return jsonObject.has(propertyName) ? jsonObject.getBoolean(propertyName) : null;
	}
	
	private Integer getIntegerPropertyFromJSON(JSONObject jsonObject, String propertyName) throws JSONException {
		return jsonObject.has(propertyName) ? jsonObject.getInt(propertyName) : null;
	}
	
	private SocketAdapter getSocketAdapter(String socketKey) {
		if (!this.socketAdapters.containsKey(socketKey)) {
			if(timer!=null){
				timer.cancel();
				timer = null;
			}
			throw new IllegalStateException("Socket isn't connected.");
		}
		return this.socketAdapters.get(socketKey);
	}
	
	private void dispatchEvent(JSONObject jsonEventObject) {
		this.webView.sendJavascript(String.format("window.Socket.dispatchEvent(%s);", jsonEventObject.toString()));		
	}	
	
	private class CloseEventHandler implements Consumer<Boolean> {
		private String socketKey;
		public CloseEventHandler(String socketKey) {
			this.socketKey = socketKey;
		}
		@Override
		public void accept(Boolean hasError) {			
			socketAdapters.remove(this.socketKey);
			
			try {
				JSONObject event = new JSONObject();
				event.put("type", "Close");
				event.put("hasError", hasError.booleanValue());
				event.put("socketKey", this.socketKey);
		
				dispatchEvent(event);
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
	}
	
	private class DataConsumer implements Consumer<byte[]> {
		private String socketKey;
		public DataConsumer(String socketKey) {
			this.socketKey = socketKey;
		}
		@SuppressLint("NewApi") 
		@Override
		public void accept(byte[] data) {
			JSONObject messageJSON = CustomGlobal.getInstance().getJson();
			if(messageJSON==null) {
				if(data.length<25) return;
				messageJSON = MessageCodec.decode(data);							
			}
			else {						
				MessageCodec.decodeData(messageJSON,data);
			}
			try {
				if(messageJSON.getBoolean("completed")){
					CustomGlobal.getInstance().setJson(null);					
					messageJSON.remove("completed");
					
					/*if(messageJSON.getInt("messageType") == CustomGlobal.getInstance().getHeartMessageType()){
						System.out.print("心跳");
						return;
					}*/
					
					String dataString  = messageJSON.toString();
					JSONObject event = new JSONObject();
					event.put("type", "DataReceived");
					event.put("data",dataString);
					event.put("socketKey", socketKey);
					dispatchEvent(event);
				}
				else {
					CustomGlobal.getInstance().setJson(messageJSON);
				}
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
		
		private List<Byte> toByteList(byte[] array) {
			List<Byte> byteList = new ArrayList<Byte>(array.length);
			for (int i = 0; i < array.length; i++) {
				byteList.add(array[i]);
			}
			return byteList;
		}
	}
	
	private class ErrorEventHandler implements Consumer<String> {
		private String socketKey;
		public ErrorEventHandler(String socketKey) {
			this.socketKey = socketKey;
		}
		@Override
		public void accept(String errorMessage) {
			if(timer!=null){
				timer.cancel();
				timer = null;
			}
			try {
				JSONObject event = new JSONObject();
				event.put("type", "Error");
				event.put("errorMessage", errorMessage);
				event.put("socketKey", socketKey);
				
				dispatchEvent(event);
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
	}
	
	private class OpenErrorEventHandler implements Consumer<String> {
		private CallbackContext openCallbackContext;
		public OpenErrorEventHandler(CallbackContext openCallbackContext) {
			this.openCallbackContext = openCallbackContext;
		}
		@Override
		public void accept(String errorMessage) {
			this.openCallbackContext.error(errorMessage);
		}
	}
	
	private class OpenEventHandler implements Consumer<Void> {
		private String socketKey;
		private SocketAdapter socketAdapter;
		private CallbackContext openCallbackContext;
		public OpenEventHandler(String socketKey, SocketAdapter socketAdapter, CallbackContext openCallbackContext) {
			this.socketKey = socketKey;
			this.socketAdapter = socketAdapter;
			this.openCallbackContext = openCallbackContext;
		}
		@Override
		public void accept(Void voidObject) {
			socketAdapters.put(socketKey, socketAdapter);
			this.openCallbackContext.success();
		}
	}
	
	static class MyTask extends java.util.TimerTask {
		static Boolean connected = false;
		private CordovaArgs args;
		private CallbackContext callbackContext;
		private SocketPlugin socket;
	  
		MyTask(CordovaArgs args, CallbackContext callbackContext, SocketPlugin socket){
			this.args = args;
			this.callbackContext = callbackContext;
			this.socket = socket;
		}
	  
		@Override
		public void run() {
			if(socket.opened){
				this.writeHeart();
			}
		}
		
		private void writeHeart(){
			try {
				String socketKey = args.getString(0);
				String data = "["+args.getString(1)+"]";
				byte[] dataBuffer;
				try{
					JSONArray jSONArray = new JSONArray(data);
					JSONObject jsonObject = jSONArray.getJSONObject(0);
					dataBuffer = MessageCodec.encode(jsonObject);
				}catch(JSONException e){
					dataBuffer = data.getBytes();
				}
			
				SocketAdapter socket = this.socket.getSocketAdapter(socketKey);
				try {
					socket.write(dataBuffer);
					JSONObject event = new JSONObject();
					event.put("type", "KeepAlive");
					event.put("data","");
					event.put("socketKey", socketKey);
					this.socket.dispatchEvent(event);
				} catch (IOException e) {
					e.printStackTrace();
				}
			} catch (JSONException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}
}
