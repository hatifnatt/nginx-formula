{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}
{% from tplroot ~ '/macro.jinja' import build_source -%}

include:
  - .prepare
  - .check
  - .service

{% set snippets_path = nginx.conf_dir ~ '/snippets' -%}
{# Build lists with all files in current subdir, later managed files will be removed from this list -#}
{% set snippets_files = salt['file.find'](snippets_path,type='fl',print='name') -%}

nginx_snippets_dir:
  file.directory:
    - name: "{{ nginx.conf_dir }}/snippets"
    - makedirs: true
    - require:
      - sls: {{ tplroot }}.prepare

{% for snippet_name, snippet in nginx.snippets|dictsort -%}
  {%- set ensure = snippet.get('ensure', 'present') %}
  {%- set source = snippet.get('source', '') %}
  {%- set snippet_path_prefix = snippet.get('path_prefix', nginx.lookup.get('path_prefix', 'templates')) %}
  {#- Remove managed snippet file name from all files list #}
  {%- if snippet_name in snippets_files %}
    {%- do snippets_files.remove(snippet_name) %}
  {%- endif %}
nginx_snippet_<{{ snippet_name }}>:
  file:
    - name: {{ snippets_path ~ '/' ~ snippet_name }}
  {%- if ensure == 'absent' %}
    - absent
  {%- elif ensure == 'present' %}
    - managed
    - source: {{ build_source(source, path_prefix=snippet_path_prefix, default_source='default/generic.conf.jinja') }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        config: {{ snippet.get('config', {})|tojson }}
    - require:
      - file: nginx_snippets_dir
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
  {%- endif %}
{% endfor -%}

{# Remove all unmanaged snippets if enabled in pillars -#}
{% if nginx.snippets_unmanaged_purge -%}
  {%- for snippet in snippets_files %}
nginx_unmanaged_snippet_<{{ snippet }}>_purge:
  file.absent:
    - name: {{ snippets_path ~ '/' ~ snippet }}
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
  {%- endfor %}
{% endif -%}
