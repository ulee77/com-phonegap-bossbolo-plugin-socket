package com.phonegap.bossbolo.plugin.socket;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;

import org.json.JSONException;
import org.json.JSONObject;

import com.bossbolo.powerb.MyZip;

public class MessageCodec {
	static public byte[]  encode(JSONObject json){
		ByteBuffer buffer = null;
		try {
			// 加密
			if(json.getInt("encrypted") != 0){
				//encryp code
			}
			byte[] data = json.getString("data").getBytes();
			// 压缩(请求数据暂时不做压缩)
			/*if(json.getInt("ziped") != 0){
				data = MyZip.gzip(data);
				//zip code
			}*/
			int datalen = data.length;
			buffer=ByteBuffer.allocate(25+datalen);
			buffer.put((byte) json.getInt("replyType"));
			buffer.put((byte) json.getInt("messageType"));
			buffer.put((byte) json.getInt("encrypted"));
			buffer.put((byte) json.getInt("ziped"));
			buffer.put((byte) json.getInt("status"));
			buffer.putLong(json.getLong("ConnectionID"));
			buffer.putLong(json.getLong("operationID"));
			buffer.putInt(datalen);
			buffer.put(data);
			
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return buffer.array();
	}
	
	public static JSONObject decode(byte[] bytes){
		ByteBuffer buffer = ByteBuffer.wrap(bytes);
		JSONObject json = decode(buffer);	
		return json;
	}
	/**
	 * 获取消息的data信息，这个地方要注意，由于缓存原因，每次接收的数据可能不够data的长度
	 * 所以要每次根据数据的长度写入相应的数据长度
	 * @param json
	 * @param buffer
	 */
	public static void decodeData(JSONObject json,byte[] bytes){
		try{	
			int dataLength = json.getInt("dataLength");
			int dataIndex = json.getInt("dataIndex");
			int blankLength = dataLength - dataIndex;
			byte[] data = (byte[])json.get("data");
			int length = bytes.length;
			
			if(blankLength<length){
				System.out.println("*********************");
				System.out.println("缓冲区比要求内容大了。。。。"+blankLength+":"+length);
				System.out.println("*********************");
				length = blankLength;
			}
			System.arraycopy(bytes,0,data,dataIndex,length);			
			//数据接收完成
			if(length == blankLength){
				///
				String dd = new String(data);
				//对于压缩的数据要进行解压
				if(json.getBoolean("ziped")){						
					json.put("data",MyZip.ungzip(data));
				}
				else json.put("data", new String(data));
				json.put("completed",true);
			}
			else {
				json.put("data",data);
				dataIndex += length;
				json.put("dataIndex",dataIndex);
			}
		}
		catch(Exception e){
			e.printStackTrace();
		}
	}
	
	public static JSONObject decode(ByteBuffer buffer){		
		//消息体长度为：25+dataLength(1,1,1,1,1,8,8,4)
		JSONObject json = new JSONObject();		
		int dataLen = 0;
		try{
			if(buffer.remaining()>=25){
				//设置状态
				json.put("completed",false);
				json.put("replyType",buffer.get());
				json.put("messageType",buffer.get());
				if(buffer.get()==1) json.put("encrypted",true);
				else json.put("encrypted",false);
				if(buffer.get()==1) json.put("ziped",true);
				else  json.put("ziped",false);        		
				json.put("status",buffer.get());        		
				int connectionID = (int)buffer.getLong();
				json.put("connectionID",connectionID);
				int operationID = (int)buffer.getLong();
				json.put("operationID",operationID);
				dataLen = buffer.getInt();
				json.put("dataLength",dataLen);
				//心跳等无需返回结果的消息
				if(dataLen==0){
					json.put("completed",true);
					json.put("data","");
					return json;
				}
				byte[] data = new byte[dataLen];
				json.put("data",data);
				json.put("dataIndex","0");
				byte[] bytes = new byte[buffer.remaining()];
				buffer.get(bytes);
				decodeData(json,bytes);	
			}
			else return null;			
		}
		catch(Exception e){
			e.printStackTrace();
		}
		return json;
	}
	
	
	static public String ByteBuffer2String(ByteBuffer buffer){
		System.out.println( " buffer= "   +  buffer);
	    Charset charset = null ;
	    CharsetDecoder decoder = null ;
	    int len = buffer.array().length;
	    CharBuffer charBuffer =  CharBuffer.allocate(buffer.array().length);
        try 
        {
           charset = Charset.forName("gb2312");
           decoder = charset.newDecoder();
        // charBuffer = decoder.decode(buffer);//用这个的话，只能输出来一次结果，第二次显示为空
           charBuffer = decoder.decode(buffer.asReadOnlyBuffer());
           System.out.println( " charBuffer= "   +  charBuffer);
           System.out.println(charBuffer.toString());
           return charBuffer.toString();
        } 
		catch (Exception ex)
        {
             ex.printStackTrace();
             return  "";
        } 
	}
	
}
