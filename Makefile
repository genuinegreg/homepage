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
		--delete-after \
		. \
		plop.io:~/_harp/gregoire-audoux.fr


clean:
	rm -Rf www