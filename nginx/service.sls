{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}

nginx_service:
  service:
    - name: {{ nginx.service.name }}
    - {{ nginx.service.status }}
    - enable: {{ nginx.service.enable }}
    {%- if nginx.service.status == 'running' %}
    - reload: {{ nginx.service.reload }}
    {%- endif %}
