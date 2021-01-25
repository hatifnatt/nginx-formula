{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}
{% from tplroot ~ '/macro.jinja' import build_source -%}

include:
  - .prepare
  - .snippets
  - .check
  - .service

nginx_main_config:
  file.managed:
    - name: "{{ nginx.conf_dir ~ '/' ~ nginx.main_config.name }}"
    - source: {{ build_source(nginx.main_config.source, default_source='default/nginx.conf.jinja') }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        config: {{ nginx.main_config.get('config', {})|tojson }}
    - require:
      - sls: {{ tplroot }}.prepare
      - sls: {{ tplroot }}.snippets
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service

{% for config_subdir, cdata in nginx.configs|dictsort -%}
  {%- set configs_path = nginx.conf_dir ~ '/' ~ config_subdir %}
  {#- Build lists with all files in current subdir, later managed files will be removed from this list #}
  {%- set config_files = salt['file.find'](configs_path,type='fl',print='name') %}
  {%- if cdata %}
nginx_config_subdir_<{{ config_subdir }}>:
  file.directory:
    - name: "{{ configs_path }}"
    - makedirs: true
    - require:
      - sls: {{ tplroot }}.prepare

    {%- for name, config in cdata|dictsort %}
      {#- Remove managed config file name from all files list #}
      {%- if name in config_files %}
        {%- do config_files.remove(name) %}
      {%- endif %}
      {%- if config %}
        {%- set ensure = config.get('ensure', 'present') %}
        {%- set source = config.get('source', '') %}
nginx_config_<{{ config_subdir ~ '/' ~ name }}>:
  file:
    - name: "{{ configs_path ~ '/' ~ name }}"
        {%- if ensure == 'absent' %}
    - absent
        {%- elif ensure == 'present' %}
    - managed
    - source: {{ build_source(source, default_source='default/generic.conf.jinja') }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        config: {{ config.get('config', {})|tojson }}
    - require:
      - sls: {{ tplroot }}.snippets
      - file: nginx_config_subdir_<{{ config_subdir }}>
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
        {%- endif %}

        {#- Remove all unmanaged config files if enabled in pillars #}
        {%- if nginx.configs_unmanaged_purge %}
          {%- for config in config_files %}
nginx_unmanaged_config_<{{ config_subdir ~'/'~ config }}>_purge:
  file.absent:
    - name: "{{ configs_path ~ '/' ~ config }}"
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
          {%- endfor %}
        {%- endif %}

      {%- endif %}
    {%- endfor %}
  {%- endif %}
{% endfor -%}
