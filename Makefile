#!make

export PYTHON_VERSION := 3.8

#SHELL := /bin/bash

build:
	{ \
  	set -e ;\
	python3 -m venv venv ;\
	. venv/bin/activate ;\
	pip install -r requirements.txt ;\
	mkdir -p dist ;\
	cd venv/lib/python3.8/site-packages ;\
	zip -r9 $${OLDPWD}/dist/athena-runner.zip . ;\
	cd $${OLDPWD} ;\
	zip -g -r ./dist/athena-runner.zip ./src/ ;\
	}

clean:
	rm -rf venv
	rm -rf ./dist/athena-runner.zip

install-dev:
	@+pipenv install --python ${PYTHON_VERSION} --dev

install:
	@+pipenv install --python ${PYTHON_VERSION}
