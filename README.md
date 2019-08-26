# CTF Scripts

### MISC
```ruby
compress/
  zipfake.rb              --  PKZip 文件伪加密
  rarfake.rb              --  RAR 文件伪加密

pcap/
  usbkeyboard.rb          --  USB 协议提取键盘输入内容
  usbmouse.rb             --  USB 协议提取鼠标输入转为图片轨迹图
  tsc_tspl_printer.rb     --  TSC TSPL 打印机，打印数据图片输出 (目前仅支持BITMAP/BAR)
  mots_check.rb           --  MOTS 攻击检测

stego/
  stegosaurus.py          --  .py/.pyc/.pyo 的隐写工具
  zwsp-steg.rb            --  ZWSP 隐写信息编码成不可见字符 (3或5个不可见字符编码)

encoder/
  base92.rb               --  base92 encode/decode
  brainfuck.rb            --  brainfuck && ook text encode/decode
  morese_decode.rb        --  莫斯电码解码

image/
  png_size_recover.rb     --  Png 文件的size恢复
```

### CRYPTO
```ruby
weblogic_password.rb      --  Weblogic 密码解密脚本
weblogic_password.py      --  Weblogic 密码解密脚本(依赖旧版Cipher)
```

### AWD
```ruby
scanner/
  synproxy-scan.rb        --  SYN Proxy Scan v2. (不支持Windows 使用)
  old-synproxy-scan.py    --  SYN Proxy Scan v1. (不建议OSX 使用)
```

### ICS
```ruby
pcap/
  ics_analysis.rb         --  ICS Protocol Analysis 字段提取统计
  tcp_payload_filter.rb   --  过滤TCP Payload 内容
  mms_extract_file.rb     --  Multimedia Messaging Service 文件提取
  asn_to_hash.rb          !-  .asn 数据转换成 Ruby Hash
```

#### 备注
```ruby
!- 为工具开发协助脚本
```
