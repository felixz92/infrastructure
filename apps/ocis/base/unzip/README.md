# unzip 

see [web-extensions](https://github.com/owncloud/web-extensions/tree/main/packages/web-app-unzip)

Copied from running container since the web-extensions containers do not support arm64 at the moment.

## License
AGPL-3.0
see [web-extensions](https://github.com/owncloud/web-extensions/blob/main/LICENSE)

```shell
container=$(docker run -d --entrypoint sleep --rm  owncloud/web-extensions:unzip-0.4.0 10)
docker cp $container:/var/lib/nginx/html/unzip/manifest.json .
docker cp $container:/var/lib/nginx/html/unzip/unzip.js .
docker cp $container:/var/lib/nginx/html/unzip/assets/z-worker-DeFJeLeg.js .
```