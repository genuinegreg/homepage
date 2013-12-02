build: force
	harp compile


deploy:
	rsync \
		-e ssh \
		-azv \
		--exclude=".git" \
		--exclude="www" \
		--delete-after \
		. \
		plop.io:~/_harp/gregoire-audoux.fr


clean:
	rm -Rf www