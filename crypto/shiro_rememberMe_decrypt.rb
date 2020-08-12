#!/usr/bin/env ruby
#
# Author L
# Shiro rememberMe decrypt
#

require 'openssl'

if ARGV.size != 1 or !File.readable?(ARGV[0]) 
  puts <<~EOF
  Usage: ruby shiro_rememberMe_decrypt.rb <rememberMe_value_file>

    e.g. ruby shiro_rememberMe_decrypt.rb a.txt > /tmp/java_serialization.bin

  EOF
  exit
end
cipher = File.binread(ARGV[0]).unpack1 'm'

Keys = %w{
0AvVhmFLUs0KTA3Kprsdag==
1AvVhdsgUs0FSA3SDFAdag==
1QWLxg+NYmxraMoxAXu/Iw==
1tC/xrDYs8ey+sa3emtiYw==
25BsmdYwjnfcWmnhAciDDg==
2A2V+RFLUs+eTA3Kpr+dag==
2AvVhdsgUs0FSA3SDFAdag==
2cVtiE83c4lIrELJwKGJUw==
2itfW92XazYRi5ltW0M2yA==
3AvVhdAgUs0FSA4SDFAdBg==
3AvVhmFLUs0KTA3Kprsdag==
3JvYhmBLUs0ETA5Kprsdag==
3qDVdLawoIr1xFd6ietnwg==
3rvVhmFLUs0KAT3Kprsdag==
4AvVhmFLUs0KTA3Kprsdag==
4BvVhmFLUs0KTA3Kprsdag==
4WCZSJyqdUQsije93aQIRg==
4rvVhmFLUs0KAT3Kprsdag==
5AvVhmFLUS0ATA4Kprsdag==
5AvVhmFLUs0KTA3Kprsdag==
5J7bIJIV0LQSN3c9LPitBQ==
5RC7uBZLkByfFfJm22q/Zw==
5aaC5qKm5oqA5pyvAAAAAA==
66v1O8keKNV3TTcGPK1wzg==
6AvVhmFLUs0KTA3Kprsdag==
6NfXkC7YVCV5DASIrEm1Rg==
6Zm+6I2j5Y+R5aS+5ZOlAA==
6ZmI6I2j3Y+R1aSn5BOlAA==
6ZmI6I2j5Y+R5aSn5ZOlAA==
7AvVhmFLUs0KTA3Kprsdag==
8AvVhmFLUs0KTA3Kprsdag==
8BvVhmFLUs0KTA3Kprsdag==
9AvVhmFLUs0KTA3Kprsdag==
9FvVhtFLUs0KnA3Kprsdyg==
A7UzJgh1+EWj5oBFi+mSgw==
Bf7MfkNR0axGGptozrebag==
ClLk69oNcA3m+s0jIMIkpg==
FP7qKJzdJOGkzoQzo2wTmA==
GAevYnznvgNCURavBhCr1w==
HWrBltGvEZc14h9VpMvZWw==
IduElDUpDDXE677ZkhhKnQ==
Is9zJ3pzNh2cgTHB4ua3+Q==
Jt3C93kMR9D5e8QzwfsiMw==
L7RioUULEFhRyxM7a2R/Yg==
MPdCMZ9urzEA50JDlDYYDg==
MTIzNDU2Nzg5MGFiY2RlZg==
MTIzNDU2NzgxMjM0NTY3OA==
MzVeSkYyWTI2OFVLZjRzZg==
NGk/3cQ6F5/UNPRh8LpMIg==
NoIw91X9GSiCrLCF03ZGZw==
NsZXjXVklWPZwOfkvk6kUA==
O4pdf+7e+mZe8NyxMTPJmQ==
OUHYQzxQ/W9e/UjiAGu6rg==
OY//C4rhfwNxCQAQCrQQ1Q==
Q01TX0JGTFlLRVlfMjAxOQ==
SDKOLKn2J1j/2BHjeZwAoQ==
SkZpbmFsQmxhZGUAAAAAAA==
U0hGX2d1bnMAAAAAAAAAAA==
U3BAbW5nQmxhZGUAAAAAAA==
U3ByaW5nQmxhZGUAAAAAAA==
UGlzMjAxNiVLeUVlXiEjLw==
V2hhdCBUaGUgSGVsbAAAAA==
WcfHGU25gNnTxTlmJMeSpw==
WuB+y2gcHRnY2Lg9+Aqmqg==
XTx6CKLo/SdSgub+OPHSrw==
XgGkgqGqYrix9lI6vxcrRw==
Y1JxNSPXVwMkyvES/kJGeQ==
YI1+nBV//m7ELrIyDHm6DQ==
Ymx1ZXdoYWxlAAAAAAAAAA==
Z3VucwAAAAAAAAAAAAAAAA==
ZAvph3dsQs0FSL3SDFAdag==
ZUdsaGJuSmxibVI2ZHc9PQ==
ZmFsYWRvLnh5ei5zaGlybw==
ZnJlc2h6Y24xMjM0NTY3OA==
a2VlcE9uR29pbmdBbmRGaQ==
a3dvbmcAAAAAAAAAAAAAAA==
aU1pcmFjbGVpTWlyYWNsZQ==
bWljcm9zAAAAAAAAAAAAAA==
bWluZS1hc3NldC1rZXk6QQ==
bXRvbnMAAAAAAAAAAAAAAA==
bya2HkYo57u6fWh5theAWw==
c+3hFGPjbgzGdrC+MHgoRQ==
c2hpcm9fYmF0aXMzMgAAAA==
c2hvdWtlLXBsdXMuMjAxNg==
cGhyYWNrY3RmREUhfiMkZA==
cGljYXMAAAAAAAAAAAAAAA==
cmVtZW1iZXJNZQAAAAAAAA==
d2ViUmVtZW1iZXJNZUtleQ==
eXNmAAAAAAAAAAAAAAAAAA==
empodDEyMwAAAAAAAAAAAA==
ertVhmFLUs0KTA3Kprsdag==
f/SY5TIve5WWzT4aQlABJA==
fCq+/xW488hMTCD+cmJ3aQ==
fsHspZw/92PrS3XrPW+vxw==
hBlzKg78ajaZuTE0VLzDDg==
i45FVt72K2kLgvFrJtoZRw==
kPH+bIxk5D2deZiIxcaaaA==
lT2UvDUmQwewm6mMoiw4Ig==
oPH+bIxk5E2enZiIxcqaaA==
r0e3c16IdVkouZgk1TKVMg==
rPNqM6uKFCyaL10AK51UkQ==
s0KTA3mFLUprK4AvVhsdag==
s2SE9y32PvLeYo+VGFpcKA==
sHdIjUN6tzhl8xZMG3ULCQ==
vXP33AonIp9bFwGl7aT7rA==
wGiHplamyXlVB11UXWol8g==
xVmmoltfpb8tTceuT5R7Bw==
yNeUgSzL/CfiWw1GALg6Ag==
yeAAo1E8BOeAYfBlm4NG9Q==
}

def aes_decrypt(key, payload)
	iv = payload[0,16]
  data = payload[16..-1]
	aes = OpenSSL::Cipher.new('aes-128-cbc')
	aes.decrypt
  aes.iv = iv
	aes.key = key.unpack1('m0')
	aes.update(payload) + (aes.final rescue '')
end

mark_head = "\xAC\xED\x00\x05".b
found = false
Keys.each do |key|
  begin
    plaintext = aes_decrypt(key, cipher)
    if (index = plaintext.index(mark_head))
      plaintext = plaintext[index..-1]
      STDERR.puts "key: #{key}"
      puts plaintext
			found = true
      break
    end
  rescue => e
    STDERR.puts "[!] key:#{key}, #{e}"
  end
end
STDERR.puts "[!] Key not found" unless found
