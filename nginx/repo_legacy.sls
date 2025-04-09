{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import nginx -%}

{% if salt['grains.get']('os_family') == 'Debian' -%}
nginx_repo:
  pkgrepo:
    {%- if nginx.use_official_repo %}
    - managed
    {%- else %}
    - absent
    {%- endif %}
    - humanname: nginx repo
    - name: deb http://nginx.org/packages/{{ grains['os']|lower }} {{ grains['oscodename']|lower }} nginx
    - file: /etc/apt/sources.list.d/nginx-official-{{ grains['oscodename']|lower }}.list
    - key_url: https://nginx.org/keys/nginx_signing.key

{% elif salt['grains.get']('os_family') == 'RedHat' -%}
nginx_repo:
  pkgrepo:
    {%- if nginx.use_official_repo %}
    - managed
    {%- else %}
    - absent
    {%- endif %}
    - name: nginx
    - humanname: nginx repo
    - baseurl: 'http://nginx.org/packages/centos/$releasever/$basearch/'
    - gpgcheck: 1
    - gpgkey: https://nginx.org/keys/nginx_signing.key
    - enabled: true

{% endif -%}
