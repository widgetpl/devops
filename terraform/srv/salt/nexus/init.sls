{%- set image_name = salt['pillar.get']('nexus:image_name', 'sonatype/nexus3') %}
{%- set image_tag = salt['pillar.get']('nexus:image_tag', '3.18.1') %}

include:
    - common

create_volume_for_docker:
    file.directory:
        - name: /var/container_data/nexus
        - user: 200
        - group: 200
        - dir_mode: 755
        - makedirs: True

run_nexus:
    docker_container.running:
        - name: nexus
        - image: {{ image_name }}:{{ image_tag }}
        - binds:
            - /var/container_data/nexus:/nexus-data
        - detach: True
        - port_bindings:
            - 80:8081
        - restart_policy: always
        - client_timeout: 120
        - require:
            - pip: 'install python modules'
            - service: 'docker'