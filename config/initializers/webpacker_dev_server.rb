# Webpacker decides whether to proxy /dev-assets to the webpack-dev-server by
# probing the port with `Socket.tcp(host, port, connect_timeout: ...)`.
#
# On macOS that probe is unreliable: a non-blocking connect to a closed port
# reports ECONNREFUSED via SO_ERROR, but the kernel answers the connect(2)
# retry — which is what Ruby inspects — with EISCONN. `Socket.tcp` then hands
# back a socket that was never connected instead of raising, so `running?` is
# always true, the proxy engages unconditionally and every pack request dies
# with ECONNREFUSED rather than falling back to the compiled packs in
# public/dev-assets. See https://bugs.ruby-lang.org/issues/22223 — fixed in
# ruby 3.4 and 4.0, not backported to the 3.3 line we run.
#
# Without a timeout the connect reports refusal correctly, and the dev server
# lives on loopback, where connects resolve immediately anyway.
if Rails.env.development?
  require 'webpacker/dev_server'

  Webpacker::DevServer.connect_timeout = nil
end
