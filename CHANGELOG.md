v1.2.1 - 2024-02-23
-------------------
- Update cloudflare trusted IP URL to include new required trailing slash
- Many dependabot bumps

v1.2.0 - 2023-06-05
-------------------
- Set `required_ruby_version` in the gemspec
- Add `trusted_request_proc` kwarg to DenyOthers middleware

v1.1.0 - 2023-03-31
-------------------
- Expand requirements to allow using Rack 3.x
- Add `trust_xff_if_private` kwarg to both middlewares
- Add `on_fail_proc` to DenyOthers middleware
- Bump various build-time dependencies

v1.0.0 - 2023-03-31
-------------------
- Initial release
