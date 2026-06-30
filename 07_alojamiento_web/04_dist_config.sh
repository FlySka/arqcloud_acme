aws cloudfront create-distribution --distribution-config file://dist-config.json --endpoint-url http://localhost:4566

aws cloudfront list-distributions --endpoint-url http://localhost:4566