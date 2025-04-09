{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import nginx as n %}

include:
  {%- if n.use_official_repo %}
  - .install
  {%- else %}
  - .clean
  {%- endif %}

# Workaround for issue https://github.com/saltstack/salt/issues/65080
# require will fail if a requisite only include other .sls
# Adding dummy state as a workaround
nginx_repo_install_init_dummy:
  test.show_notification:
    - text: "Workaround for salt issue #65080"
