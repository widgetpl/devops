create_volume_for_docker:
    file.directory:
        - name: /var/container_data/nexus
        - user: 200
        - group: 200
        - dir_mode: 755
        - makedirs: True

run_jenkins:
    docker_container.running:
        - name: nexus
        - image: sonatype/nexus3:3.18.1
        - binds:
            - /var/container_data/nexus:/nexus-data
        - detach: True
        - port_bindings:
            - 80:8081
        - restart_policy: always