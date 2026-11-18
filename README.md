# blog-haproxy-http-headers

Companion code for the blog post
[HAProxy HTTP Headers Debugging: A Complete Troubleshooting Guide](https://blog.bsdserver.nl/haproxy-http-headers-debugging-a-complete-troubleshooting-guide/).

It builds the post's **Complete Debug Configuration** on one HAProxy node:

- **Header capture and logging:**
  - `capture request/response header` for Host, User-Agent, X-Forwarded-For, Authorization,
    Content-Type, Cookie and more;
  - the post's detailed `log-format`;
  - `log /dev/log local0 debug`, written to `/var/log/haproxy.log` by rsyslog.
- **A unique request ID** (`X-Request-ID`) on the request and the response.
- **Forwarding headers:**
  - spoofed `X-Forwarded-For`, `X-Real-IP` and `X-Forwarded-Proto` are removed;
  - HAProxy then sets its own `X-Forwarded-*` and `X-Real-IP`.
- **Response headers:** `Server` and `X-Powered-By` are removed; `X-Backend-Server`,
  `X-Request-ID` and `X-Response-Time` are added.
- **Debug endpoints** answered by HAProxy itself: `/debug/headers` (plain text) and `/debug/json`.
- **Lua header dump:** the post's `debug-headers.lua`, installed in `/etc/haproxy/lua/`.
  - It is off by default, as in the post.
  - With `haproxy_header_debug_lua_enabled: true` it is loaded and answers `/debug/headers`.
- **Stats** at `:8404/stats` and Prometheus metrics at `:8404/metrics`.

HAProxy comes from the official repositories:

- Ubuntu 24.04: `ppa:vbernat/haproxy-3.3`. 3.3 is the newest branch built for 24.04. It is
  short-lived and not LTS.
- Debian 13: haproxy.debian.net, 3.4 LTS.

Both builds include Lua.

## Requirements

- Terraform >= 1.6 and a Proxmox VE API token, if you want Terraform to create the VM.
- ansible-core >= 2.15 on your workstation.
- Web servers that answer `GET /health`. The default is the post's `192.168.1.10-11:8080`.
  - To try it on a single VM, use the demo backends below.

## Quick start

```bash
# 1. VM (optional: any Ubuntu 24.04 or Debian 13 host works)
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init && terraform apply
terraform output -raw ansible_inventory > ../ansible/inventory.yml

# 2. HAProxy, with your web servers in group_vars/all/vars.yml ...
cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
# ... or as a single-VM demo with two header-echo backends on 127.0.0.1:8081/8082
ansible-playbook site.yml -e @../tests/demo-vars.yml

# 3. The post's checks
ansible-playbook ../tests/verify.yml
curl -H "X-Custom: test" http://10.0.0.10/debug/headers
curl -s -D- http://10.0.0.10/ -o /dev/null        # X-Backend-Server, X-Request-ID, no Server header
ssh 10.0.0.10 sudo tail -f /var/log/haproxy.log    # captured headers in {...}
```

## Variables

All variables are in `ansible/roles/haproxy_header_debug/defaults/main.yml`.

| Variable | Default | Meaning |
|----------|---------|---------|
| `haproxy_install_version` | `3.3` (Ubuntu), `3.4` (Debian) | HAProxy branch from the official repository |
| `haproxy_header_debug_servers` | `web1`/`web2` at 192.168.1.10-11:8080 | backend servers: `name`, `address`, `port` |
| `haproxy_header_debug_log_level` | `debug` | level on `log /dev/log local0` |
| `haproxy_header_debug_lua_enabled` | `false` | load the Lua header dump; it then answers `/debug/headers` |
| `demo_backend_enabled` | `false` | DEMO: run two header-echo servers on the HAProxy host |

As the post warns:

- The configuration logs `Authorization` and `Cookie` (truncated) and exposes debug endpoints.
- Use it for troubleshooting, not as a permanent production configuration.

There are no secrets. `group_vars/all/vault.yml.example` only exists so all companion repos have
the same layout.

## How it was tested

- Fresh Ubuntu 24.04 systemd container, `site.yml -e @../tests/demo-vars.yml` run twice:
  - the second run reports `changed=0`;
  - then `tests/verify.yml` passes.
- Lua mode (`-e haproxy_header_debug_lua_enabled=true`): run twice (`changed=0` the second time);
  `/debug/headers` then returns the Lua dump.
- HAProxy 3.3.17 (PPA), Lua 5.4.6.
- CI (`.gitlab-ci.yml`) runs yamllint, ansible-lint (production profile), `terraform fmt`,
  `validate` and tflint.

## License

MIT
