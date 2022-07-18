FROM alpine:latest

RUN apk add --no-cache perl lighttpd

COPY www /var/www

COPY cgi-lib.pl /usr/local/lib/perl5/site_perl/

EXPOSE 80/tcp

ENTRYPOINT ["/usr/sbin/lighttpd"]

CMD ["-D", "-f", "/var/www/lighttpd.conf"]
