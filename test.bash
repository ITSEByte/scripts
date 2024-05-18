apt install lighttpd-mod-openssl -y

mkdir -p /etc/lighttpd/ssl/

openssl req -newkey rsa:2048 -nodes -keyout pihole.key -x509 -days 365 -out /etc/lighttpd/ssl/pihole.crt

cat pihole.key pihole.crt > combined.pem

chown www-data -R /etc/lighttpd/ssl/

cd /etc/lighttpd/conf-enabled/

cat << EOF > 20-pihole-external.conf
#Loading openssl
server.modules += ( "mod_openssl" )

setenv.add-environment = ("fqdn" => "true")
$SERVER["socket"] == ":443" {
	ssl.engine  = "enable"
	ssl.pemfile = "/etc/lighttpd/ssl/combined.pem"
	ssl.openssl.ssl-conf-cmd = ("MinProtocol" => "TLSv1.3", "Options" => "-ServerPreference")
}

# Redirect HTTP to HTTPS
$HTTP["scheme"] == "http" {
    $HTTP["host"] =~ ".*" {
        url.redirect = (".*" => "https://%0$0")
    }
}
EOF

systemctl restart lighttpd.service