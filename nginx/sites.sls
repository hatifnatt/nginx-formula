{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}
{% from tplroot ~ '/macro.jinja' import build_source -%}

include:
  - .prepare
  - .snippets
  - .check
  - .service

{#- Do not render any states if sites_available_dir and sites_enabled_dir parameters not set #}
{% if nginx.sites_available_dir and nginx.sites_enabled_dir -%}

{% set sites_available_path = nginx.conf_dir ~ '/' ~ nginx.sites_available_dir -%}
{% set sites_enabled_path = nginx.conf_dir ~ '/' ~ nginx.sites_enabled_dir -%}
{#- Build lists with all avilable and enabled sites #}
{% set sites_available_files = salt['file.find'](sites_available_path,type='fl',print='name') -%}
{% set sites_enabled_files = salt['file.find'](sites_enabled_path,type='fl',print='name') -%}

nginx_sites_available_dir:
  file.directory:
    - name: "{{ sites_available_path }}"
    - makedirs: true
    - require:
      - sls: {{ tplroot }}.prepare

nginx_sites_enabled_dir:
  file.directory:
    - name: "{{ sites_enabled_path }}"
    - makedirs: true
    - require:
      - sls: {{ tplroot }}.prepare

{%- for site_name, site_config in nginx.sites|dictsort %}
  {#- Remove managed site from all avilable site files #}
  {%- if site_name in sites_available_files %}
    {%- do sites_available_files.remove(site_name) %}
  {%- endif %}
  {#- Remove managed site from all enabled site files #}
  {%- if site_name in sites_enabled_files %}
    {%- do sites_enabled_files.remove(site_name) %}
  {%- endif %}

  {%- if site_config %}
    {%- set ensure = site_config.get('ensure', 'present') %}
    {%- set enable = site_config.get('enable', true) %}
    {%- set source = site_config.get('source', '') %}
    {#- Create site configuration file #}
nginx_site_<{{ site_name }}>:
  file:
    - name: "{{ sites_available_path ~ '/' ~ site_name }}"
    {%- if ensure == 'absent' %}
    - absent
    {%- elif ensure == 'present' %}
    - managed
    - source: {{ build_source(source, default_source='default/generic.conf.jinja') }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        config: {{ site_config.get('config', {})|tojson }}
    - require:
      - sls: {{ tplroot }}.snippets
      - file: nginx_sites_available_dir
    {%- endif %}
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service

    {#- Enable site configuration file #}
    {%- if enable and ensure == 'present' %}
nginx_site_<{{ site_name }}>_enable:
  file.symlink:
    - name: "{{ sites_enabled_path ~ '/' ~ site_name }}"
    - target: "{{ sites_available_path ~ '/' ~ site_name }}"
    - require:
      - file: nginx_sites_enabled_dir
      - file: nginx_site_<{{ site_name }}>
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service

    {%- else %}

nginx_site_<{{ site_name }}>_disable:
  file.absent:
    - name: "{{ sites_enabled_path ~ '/' ~ site_name }}"
    {#- Just to run states in more logical order: disabe site before removing config file #}
    - require_in:
      - file: nginx_site_<{{ site_name }}>
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
    {%- endif %}

  {%- endif %}
{%- endfor %}

{#- Clean up unmanaged sites #}
{% if nginx.sites_unmanaged == 'purge' or nginx.sites_unmanaged == 'disable' %}
  {%- for site in sites_enabled_files %}

nginx_unmanaged_enabled_site_<{{ site }}>_disable:
  file.absent:
    - name: "{{ sites_enabled_path ~ '/' ~ site }}"
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
  {%- endfor %}

  {%- if nginx.sites_unmanaged == 'purge' %}
    {%- for site in sites_available_files %}
nginx_unmanaged_available_site_<{{ site }}>_purge:
  file.absent:
    - name: "{{ sites_available_path ~ '/' ~ site }}"
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
    {%- endfor %}
  {%- endif %}
{% endif -%}

{#- Show warning about empty values for nginx:sites_available_dir and nginx:sites_enabled_dir #}
{% else -%}
nginx_sites_functionality_disabled:
  test.configurable_test_state:
    - name: nginx sites functionality disabled
    - changes: false
    - result: true
    - comment: |-
          To enable sites functionality nginx:sites_available_dir and nginx:sites_enabled_dir
          parameters must be set to non empty values. Current values:
          sites_available_dir: '{{ nginx.sites_available_dir }}'
          sites_enabled_dir: '{{ nginx.sites_enabled_dir }}'
          No actual changes are made
{% endif -%}
