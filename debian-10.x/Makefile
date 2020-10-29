PACKER_FILE = packer.pkr.hcl

OUTPUT_DIR = output
## availabe versions, 10.6.0, 10.5.0, 10.4.0, 10.3.0
VERSION = 10.5.0
OUTPUT_NAME = debian-$(VERSION).qcow2
ifeq ($(VERSION), 10.6.0)
	BASEURL= https://cdimage.debian.org/cdimage/release
else
	BASEURL= https://cdimage.debian.org/cdimage/archive
endif
OUTPUT = $(OUTPUT_DIR)/$(OUTPUT_NAME)
S3BUCKET = xcloud-images
PACKER_FLAGS = -var output_dir="$(OUTPUT_DIR)" -var output_name="$(OUTPUT_NAME)" -var version="$(VERSION)" -var baseurl="$(BASEURL)"
PACKER_BUILD_FLAGS = 





all:
	$(MAKE) $(OUTPUT) create converge verify destroy push

clean:
	rm -rf $(OUTPUT_DIR)

really-clean: clean
	rm -rf packer_cache/ .kitchen/ .gems/


$(OUTPUT): $(PACKER_FILE)
	$(MAKE) build

build: validate $(PACKER_FILE)
	packer build $(PACKER_FLAGS) $(PACKER_BUILD_FLAGS) $(PACKER_FILE)

validate: $(PACKER_FILE)
	packer validate $(PACKER_FLAGS) $(PACKER_FILE)

$(KITCHEN_DISK): $(KITCHEN_BASE_IMAGE)
	qemu-img create -f qcow2 -o backing_file=$< $@ 10G

test create setup converge destroy verify list login: .gems
	OUTPUT=./$(OUTPUT) bundle exec kitchen $@

.gems: Gemfile
	bundle install --path $@
	touch $@ # Be sure the target is newer than the source

push: 
	aws s3 sync $(OUTPUT_DIR)/ s3://$(S3BUCKET)/ 
