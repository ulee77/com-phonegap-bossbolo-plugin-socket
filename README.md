# com-phonegap-bossbolo-plugin-socket
布络phonegap socket插件

## 安装插件
```sh
phonegap plugin add com-phonegap-bossbolo-plugin-socket
```
或
```sh
phonegap plugin add https://github.com/ulee77/com-phonegap-bossbolo-plugin-socket.git
```

##插件依赖
依赖于主框架插件：https://github.com/ulee77/com-phonegap-bossbolo-plugin

##平台支持
- phoengap 5+
- Android 4+
- IOS 5+

##通用接口说明

创建一个新的socket对象:
```sh
var socket = new Socket();
```

设置socket消息回调
```sh
socket.onData = function(receive) {
  // 得到服务器receive，receive为字符串
};
socket.onError = function(errorMessage) {
  // 当socket发生错误时触发，并得到错误信息
};
socket.onClose = function(hasError) {
  // 当socket关闭触发
};
```

打开连接
```sh
socket.open(
  "8.8.8.8",    //IP
  1234,         //端口
  function() {
    // 打开成功时触发
  },
  function(errorMessage) {
    // 打开失败时触发
  });
```

向服务器发送消息
```sh
socket.write(data);
```

发送并关闭通讯通道
```sh
socket.shutdownWrite();
```

关闭socket连接
```sh
socket.close();
```

###socket状态
通过调用Socket.State可以获取socket当前连接状态，状态值如下：
- `Socket.State.CLOSED`
- `Socket.State.OPENING`
- `Socket.State.OPENED`
- `Socket.State.CLOSING`

