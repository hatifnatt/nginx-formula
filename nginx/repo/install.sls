{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import nginx as n %}
{%- from tplroot ~ '/macro.jinja' import format_kwargs %}

{%- if n.install %}
  {#- If nginx:use_official_repo is true official repo will be configured #}
  {%- if n.use_official_repo %}

    {#- Install required packages if defined #}
    {%- if n.repo.prerequisites %}
nginx_repo_install_prerequisites:
  pkg.installed:
    - pkgs: {{ n.repo.prerequisites|tojson }}
    {%- endif %}

    {#- If only one repo configuration is present - convert it to list #}
    {%- if n.repo.config is mapping %}
      {%- set configs = [n.repo.config] %}
    {%- else %}
      {%- set configs = n.repo.config %}
    {%- endif %}
    {%- for config in configs %}
      {#- Install keyring if provided, for Debian based systems only #}
      {%- if 'keyring' in config and config.keyring %}
      {%- set key_basename = salt['file.basename'](config.keyring) %}
nginx_repo_install_keyring_{{ loop.index0 }}:
  file.managed:
    - name: {{ '/usr/share/keyrings/'|path_join(key_basename) }}
    - source: {{ config.keyring }}
      {%- endif %}

nginx_repo_install_{{ loop.index0 }}:
  pkgrepo.managed:
    {{- format_kwargs(config) }}
      {%- if 'keyring' in config and config.keyring %}
    - require:
      - file: nginx_repo_install_keyring_{{ loop.index0 }}
      {%- endif %}
    {%- endfor %}

  {#- Official repo configuration is not requested #}
  {%- else %}
nginx_repo_install_method:
  test.show_notification:
    - name: nginx_repo_install_method
    - text: |
        Official repo configuration is not requested.
        If you want to configure repository set 'nginx:use_official_repo' to true.
        Current value of nginx:use_official_repo: '{{ n.use_official_repo }}'
  {%- endif %}

{#- nginx is not selected for installation #}
{%- else %}
nginx_repo_install_notice:
  test.show_notification:
    - name: nginx_repo_install
    - text: |
        nginx is not selected for installation, current value
        for 'nginx:install': {{ n.install|string|lower }}, if you want to install nginx
        you need to set it to 'true'.

{%- endif %}
