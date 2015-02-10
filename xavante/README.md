Install
=======
Install needed packages
* `$ sudo apt-get install lua5.1 liblua5.1-0-dev libncurses5-dev libcurl4-openssl-dev subversion git`
Install LuaRocks (https://rocks.moonscript.org/)
* `$ wget http://luarocks.org/releases/luarocks-2.2.0.tar.gz`
* `$ tar zxpf luarocks-2.2.0.tar.gz`
* `$ cd luarocks-2.2.0`
* `$ ./configure; sudo make bootstrap`
Install needed rocks
* `$ sudo luarocks --only-server=http://rocks.moonscript.org/dev install wsapi-xavante cvs-1`
* `$ sudo luarocks install orbit`
* `$ sudo luarocks install penlight`
* `$ sudo luarocks install luajson`
* `$ sudo luarocks install luasocket`

Make it run as a service
* `$ sudo ./daemonize-xavante-launch.lua`
