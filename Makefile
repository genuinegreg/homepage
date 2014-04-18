build: force
	harp compile


deploy:
	rsync \
		-e ssh \
		-azv \
		--exclude=".git" \
		--exclude="www" \
		--exclude="Makefile" \
		--exclude="README.md" \
		--exclude=".idea" \
		--delete-after \
		. \
		plop.io:~/_harp/gregoire-audoux.fr


clean:
	rm -Rf www


force:
	true
