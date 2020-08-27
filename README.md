
Use containerized dell-idrac-adm in order to mount an iso on remote fileserver (http), and reboot the server from it.

- Build
```
git clone git@github.com:jparrill/racadm-image.git
cd racadm-image
podman build . -t idracbootfromiso
```

- Usage
```
podman run --net=host idracbootfromiso -r 10.19.0.84 -u admin -p "aw3s0m3P4ssw0rD" -i http://192.168.5.1/fedcos-ocp.iso
podman run --net=host idracbootfromiso -r 10.19.0.85 -u admin -p "aw3s0m3P4ssw0rD" -i http://192.168.5.1/fedcos-ocp.iso
podman run --net=host idracbootfromiso -r 10.19.0.86 -u admin -p "aw3s0m3P4ssw0rD" -i http://192.168.5.1/fedcos-ocp.iso
```

Initialize the first virtual disk first
```
podman run --net=host idracbootfromiso -d -r 10.19.0.86 -u admin -p "aw3s0m3P4ssw0rD" -i http://192.168.5.1/fedcos-ocp.iso
```
