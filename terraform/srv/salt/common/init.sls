uptodate:
    pkg.uptodate:
        - refresh: True

install pakages:
    pkg.installed:
        - pkgs:
            - docker.io
            - python3
            - python3-pip

install python modules:
    pip.installed:
        - pkgs:
            - docker
            - urllib3
        - upgrade: True
        - bin_env: '/usr/bin/pip3'
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