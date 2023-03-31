This is a small Rack middleware for use with the [Cloudflare](https://www.cloudflare.com/) CDN.

We include two middlewares:

 * `Rack::CloudflareMiddleware::RewriteRemoteAddr` swaps in `CF-Connecting-IP` for `REMOTE_ADDR` if and only if the "real" remote address is a trusted Cloudflare source IP address.
 * `Rack::CloudflareMiddleware::DenyOthers` returns a 401 for all requests where `REMOTE_ADDR` is not Cloudflare

If you're using Rails, you may want to use [cloudflare-rails](https://github.com/modosc/cloudflare-rails) instead.

This library uses Faraday to dynamically update the list of trusted remote IPs every few hours, and includes a checked-in snapshot which will be used if the dynamic updater fails.

This library is licensed under the ISC license, a copy of which can be found at [LICENSE.txt](LICENSE.txt). "Cloudflare" is a registered trademark of Cloudflare, Inc and is used as per the [Cloudflare Trademark Guidelines](https://www.cloudflare.com/trademark/)

### Usage

Add this library to your Gemfile (or otherwise include it with your application), and add it as a middleware in your `config.ru`; for example, if you're using [Sinatra](), this might look like:

```ruby
require "rack/cloudflare_middleware"
require "sinatra"
require "./app"

use Rack::CloudflareMiddleware::DenyOthers, allow_private: true
use Rack::CloudflareMiddleware::RewriteRemoteAddr

run Sinatra::Application
```

The `allow_private` kwarg to `DenyOthers` controls whether or not private and loopback addresses are allowed through. Whether or not you should set this depends on the exact specifics of your deployment environment; often it should be set in development, but not in production.

`DenyOthers` also takes an `on_fail_proc` kwarg which receives the request environment and should return an appropriate error response (as a standard Rack tuple of `(status, headers, body)`). Example usage:

```ruby
require "rack/cloudflare_middleware"

use Rack::CloudflareMiddleware::DenyOthers, on_fail_proc: ->(env) do
  MyLogger.warn "Bad request from #{env["REMOTE_ADDR"]}"
  [403, {"Content-Type" => "text/plain"}, ["you did a bad thing"]]
end
```

Both middlewares also include a convenience called `trust_xff_if_private` mode; this will change them to use the right-most contents of `X-Forwarded-For` as `REMOTE_ADDR` if and only if the actual `REMOTE_ADDR` is a private address. This is a moderately-unsafe option, but may be required if your application provider has made poor choices in routing technologies (and, for example, is required on Heroku). If you're in this state, you should tell your provider to use the PROXY protocol internally instead of `X-Forwarded-For`. There have been many security issues related to Heroku's poor parsing of `X-Forwarded-For` in their router/load-balancer layer, and may be more in the future.
