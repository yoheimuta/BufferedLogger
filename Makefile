demo/install-pod:demo/install-gem
	cd Demo; bundle exec pod install

demo/install-gem:
	cd Demo;  bundle install --path vendor/bundle
