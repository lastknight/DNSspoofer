DIEns
    by Matteo G.P. Flora <mF@thefool.it>
    http://www.thefool.it

== DESCRIPTION:
DIEns is a very simple DNS monitoring utility, very useful in debugging what happens on DNS level on your hosts and/or your company. DIEns (pron. DIE en es) Forwarder able to poison requests. Basis for FoolDNS poisoner

== FEATURES:
* Forwards DNS requests to different servers

== LOG FORMAT:
Every request has the following format:

<tt>
[timestamp] - {client } - {query_type} - {requested_host} ({number_or_requests})
[Tue Apr 06 16:23:40 +0200 2010] - 127.0.0.1 -> IN::AAAA - virgilioparliamone.myblog.it (2)
</tt>

When a new request is found "!!!!" is prepended to the requested host.

== TODO:
* Efficent Poisoning

== RUNNING:
  sudo ruby server.rb

  You _MUST run it with superuser priviledges_ to be able to bind port 53

== REQUIREMENTS:
* resolv
* socket

== LICENSE:
                   COPYRIGHT 2009 The Fool s.r.l.
