{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}

{% if nginx.package is string -%}
  {%- if nginx.version %}
    {% set pkgs = [{nginx.package: nginx.version}] %}
  {%- else %}
    {% set pkgs = [nginx.package] %}
  {%- endif %}
{% elif nginx.package is iterable and nginx.package is not string -%}
  {%- set pkgs = nginx.package %}
{% endif -%}

include:
  - .repo
  - .check
  - .selinux
  - .service

nginx_pkg:
  pkg.installed:
    - pkgs: {{ pkgs|tojson }}
    {% if grains.os_family == 'RedHat' and nginx.use_official_repo -%}
    - fromrepo: nginx
    {% endif -%}
    - require:
      - sls: {{ tplroot }}.repo
    - require_in:
      - cmd: nginx_check_config
      - sls: {{ tplroot }}.selinux
    - watch_in:
      - service: nginx_service
