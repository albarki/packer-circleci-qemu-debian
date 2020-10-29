# packer-circleci-qemu-debian

## How to build debian-10.x image 

- the latest version of debian is 10.6.0
```
make all
```
- if you want to build older version, example 10.5.0 please do 

```
sed -i 's/VERSION = .*/VERSION = 10.5.0/g' debian-10.x/Makefile
make all
```
