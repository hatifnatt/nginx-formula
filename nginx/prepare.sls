{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}

nginx_conf_dir:
  file.directory:
    - name: "{{ nginx.conf_dir }}"
    - makedirs: true
