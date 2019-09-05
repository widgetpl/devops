base:
  '*':
    - common
  'roles:jenkins':
    - match: grain
    - jenkins
  'roles:nexus':
    - match: grain
    - nexus