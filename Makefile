.PHONY: compile publish

init:
	@jb update

compile:
	@rm -rf /tmp/dashboards
	@mkdir -p /tmp/dashboards
	@for f in src/*.jsonnet; do \
		jsonnet -J vendor $$f | \
		jq "{ \"dashboard\": ., \"overwrite\": true }" > \
		/tmp/dashboards/$$(basename $$f .jsonnet).json; \
	done

publish: compile
	@for f in /tmp/dashboards/*.json; do \
		curl -X POST \
			-H 'Content-Type: application/json' \
			-H 'Accept: application/json' \
			"http://host.docker.internal:3000/api/dashboards/db" \
			-d "@$$f" \
			&& echo ""; \
	done

traffic:
	@k6 run ./scripts/load-tests.js