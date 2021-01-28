{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}
{% from tplroot ~ '/macro.jinja' import build_source, format_kwargs -%}

{# By default don't install packages required to issue self signed certificates -#}
{% set self_signing = {'required': false} -%}

include:
  - .prepare
  - .check
  - .service

nginx_certs_dir:
  file.directory:
    - name: "{{ nginx.tls.certs_dir }}"
    - makedirs: true

{% for name, data in nginx.tls.certs|dictsort -%}
  {%- set key_name = name ~ '.key' %}
  {%- set cert_name = name ~ '.crt' %}
  {%- set ensure = data.get('ensure', 'present') %}
  {#- If source provided for both private key and certificate simply manage files #}
  {%- if ('key_source' in data and data.key_source
          and 'cert_source' in data and data.cert_source)
        or ('key_content' in data and data.key_content
            and 'cert_content' in data and data.cert_content) %}

nginx_provided_tls_key_<{{ name }}>:
  file:
    {%- if ensure == 'absent' %}
    - absent
    {%- elif ensure == 'present' %}
    - managed
    - name: "{{ nginx.tls.certs_dir ~ '/' ~ key_name }}"
      {#- Key data from pillar have more priority than source file #}
      {%- if 'key_content' not in data %}
    - source: {{ build_source(data.key_source, path_prefix='certs', default_source=key_name) }}
      {%- else %}
    - contents: {{ data.key_content|tojson }}
      {%- endif %}
    - mode: 640
    {%- endif %}
    - require:
      - file: nginx_certs_dir
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service

nginx_provided_tls_cert_<{{ name }}>:
  file:
    {%- if ensure == 'absent' %}
    - absent
    {%- elif ensure == 'present' %}
    - managed
    - name: "{{ nginx.tls.certs_dir ~ '/' ~ cert_name }}"
      {#- Certificate data from pillar have more priority than source file #}
      {%- if 'cert_content' not in data %}
    - source: {{ build_source(data.cert_source, path_prefix='certs', default_source=cert_name) }}
      {%- else %}
    - contents: {{ data.cert_content|tojson }}
      {%- endif %}
    - mode: 640
    {%- endif %}
    - require:
      - file: nginx_certs_dir
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service

  {#- Otherwise create self signed TLS (SSL) certificate if required data provided #}
  {%- elif 'cert_params' in data and data.cert_params %}
    {#- Update requirement for self signed certificates #}
    {%- do self_signing.update({'required': true}) -%}
    {%- if ensure == 'present' %}
nginx_selfsigned_tls_key_<{{ name }}>:
  x509.private_key_managed:
    - name: "{{ nginx.tls.certs_dir ~ '/' ~ key_name }}"
    - mode: 640
    - require:
      - file: nginx_certs_dir
    - onchanges_in:
      - cmd: nginx_check_config
    - require:
      - pkg: nginx_tls_prereq_packages
    - watch_in:
      - service: nginx_service

nginx_selfsigned_tls_cert_<{{ name }}>:
  x509.certificate_managed:
    - name: "{{ nginx.tls.certs_dir ~ '/' ~ cert_name }}"
    - signing_private_key: {{ nginx.tls.certs_dir ~ '/' ~ key_name }}
    {{- format_kwargs(data.cert_params) }}
    - mode: 640
    - require:
      - file: nginx_certs_dir
      - x509: nginx_selfsigned_tls_key_<{{ name }}>
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service

    {%- elif ensure == 'absent' %}
nginx_selfsigned_tls_key_<{{ name }}>:
  file.absent:
    - name: "{{ nginx.tls.certs_dir ~ '/' ~ key_name }}"
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service

nginx_selfsigned_tls_cert_<{{ name }}>:
  file.absent:
    - name: "{{ nginx.tls.certs_dir ~ '/' ~ cert_name }}"
    - onchanges_in:
      - cmd: nginx_check_config
    - watch_in:
      - service: nginx_service
    {%- endif %}
  {%- endif %}

{% endfor -%}

{# Install packages required for self signed certificates -#}
{% if self_signing.required -%}
nginx_tls_prereq_packages:
  pkg.installed:
    - pkgs: {{ nginx.tls.packages|tojson }}
{% endif -%}

{#- TODO
    Create dhparam from source file / pillar
    Generate dhparam with openssl / Salt module (if available) -#}
