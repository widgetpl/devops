{% set packages = salt['pillar.get']('packages', {}) %}

uptodate:
    pkg.uptodate:
        - refresh: True

install-custom-packages:
  pkg.installed:
    - pkgs:
{% for pkg in packages %}
      - {{ pkg }}
{% endfor %}

install pakages:
    pkg.installed:
        - pkgs:
        {%- for pkg in packages %}
            - {{ pkg }}
        {%- endfor %}

install python modules:
    pip.installed:
        - pkgs:
            - docker
            - docker-compose
        - upgrade: True
        - bin_env: '/usr/bin/pip'
        - reload_modules: True
        - require:
            - pkg: 'install pakages'

ubuntu:
    user.present:
        - groups:
            - docker

docker:
    service.running:
        - enable: True