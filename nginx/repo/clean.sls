{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import nginx as n %}

{#- Remove any configured repo form the system #}
{#- If only one repo configuration is present - convert it to list #}
{%- if n.repo.config is mapping %}
  {%- set configs = [n.repo.config] %}
{%- else %}
  {%- set configs = n.repo.config %}
{%- endif %}
{%- for config in configs %}
nginx_repo_clean_{{ loop.index0 }}:
  {%- if grains.os_family != 'Debian' %}
  pkgrepo.absent:
    - name: {{ config.name | yaml_dquote }}
  {%- else %}
  {#- Due bug in pkgrepo.absent we need to manually remove repository '.list' files
      See https://github.com/saltstack/salt/issues/61602 #}
  file.absent:
    - name: {{ config.file }}
  {%- endif %}

  {#- Remove keyring if present #}
  {%- if 'keyring' in config and config.keyring %}
  {%- set key_basename = salt['file.basename'](config.keyring) %}
nginx_repo_clean_keyring_{{ loop.index0 }}:
  file.absent:
    - name: {{ '/usr/share/keyrings/'|path_join(key_basename) }}
  {%- endif %}

{%- endfor %}
