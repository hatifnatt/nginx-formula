{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import nginx as n %}

include:
  {%- if n.use_official_repo %}
  - .install
  {%- else %}
  - .clean
  {%- endif %}
