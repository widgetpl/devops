{%- set image_name = salt['pillar.get']('jenkins:image_name', 'jenkins/jenkins') %}
{%- set image_tag = salt['pillar.get']('jenkins:image_tag', '2.190-jdk11') %}

include:
    - common

create_volume_for_docker:
    file.directory:
        - name: /var/container_data/jenkins
        - user: ubuntu
        - group: ubuntu
        - dir_mode: 755
        - makedirs: True

run_jenkins:
    docker_container.running:
        - name: jenkins
        - image: {{ image_name }}:{{ image_tag }}
        - binds:
            - /var/container_data/jenkins:/var/jenkins_home
        - detach: True
        - port_bindings:
            - 80:8080
            - 50000:50000
        - restart_policy: always
        - client_timeout: 120
        - require:
            - pip: 'install python modules'
            - service: 'docker'