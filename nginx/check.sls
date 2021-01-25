{# Check config before restarting service, do not restart if check failed #}
nginx_check_config:
  cmd.run:
    - name: nginx -t
    - require_in:
      - service: nginx_service
