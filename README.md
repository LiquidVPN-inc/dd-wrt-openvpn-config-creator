dd-wrt-openvpn-config-creator
=============================

Create DD-WRT OpenVPN Configurations for virtually all VPN services that rely on username and password to connect.


Usage: From any Linux terminal session including your DD-WRT router upload
Conn_Creator.sh and your VPN services ca.crt and optional ta.key then run it
with user@DD-WRT~:sh Conn_Creator.sh then follow the prompts. It will generate
a new script that you can then copy and paste into your DD-WRT routers Admin/Commands section
in the WebUI. This script should work with any VPN service that uses a user/pass. 
You may need to change the cipher AES-256-CBC if your VPN service uses BF-CBC or AES-128-CBC.
Look in a .ovpn file or ask your provider for the cipher if you are unsure. 

For an Example of how to use the script that this generator creates on your DD-WRT router there is a video posted here https://www.youtube.com/watch?v=pm3EyorNZig
