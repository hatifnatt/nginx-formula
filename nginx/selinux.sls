{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}

{%- if nginx.selinux.manage %}
  {%- if salt['grains.get']('selinux:enabled', False) %}
include:
  - .service

{# Install packages required for SElinux policy management -#}
nginx_selinux_prereq_packages:
  pkg.installed:
    - pkgs: {{ nginx.selinux.packages|tojson }}

nginx_selinux_httpd_can_network_relay:
  selinux.boolean:
    - name: httpd_can_network_relay
    - value: {{ nginx.selinux.httpd_can_network_relay }}
    - persist: true
    - watch_in:
      - service: nginx_service

nginx_selinux_httpd_can_network_connect:
  selinux.boolean:
    - name: httpd_can_network_connect
    - value: {{ nginx.selinux.httpd_can_network_connect }}
    - persist: true
    - watch_in:
      - service: nginx_service

    {%- for l in nginx.selinux.listen_ports %}
      {%- set port = l.port %}
      {%- set protocol = l.get('protocol', 'tcp') %}
nginx_selinux_allow_to_listen_on_port_{{ protocol }}/{{ port }}:
  selinux.port_policy_present:
    - name: nginx_selinux_allow_to_listen_on_port_{{ protocol }}/{{ port }}
    - protocol: {{ protocol }}
    - port: {{ port }}
    - sel_type: http_port_t
    - watch_in:
      - service: nginx_service
    {%- endfor %}

  {%- else %}
nginx_selinux_not_applicable:
  test.show_notification:
    - name: nginx_selinux_not_applicable
    - text: |
        SELinux is not enabled or not available on the current system

  {%- endif %}

{%- else %}
nginx_selinux_management_not_enabled:
  test.show_notification:
    - name: nginx_selinux_management_not_enabled
    - text: |
        This formula of SELinux management is not enabled, you can enable it by setting
        'nginx:selinux:manage: true', current value is '{{ nginx.selinux.manage|string|lower }}'

{%- endif %}
