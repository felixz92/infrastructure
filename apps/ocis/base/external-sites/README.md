# unzip 

see [web-extensions](https://github.com/owncloud/web-extensions/tree/main/packages/web-app-external-sites)

Copied from running container since the web-extensions containers do not support arm64 at the moment.

## License
AGPL-3.0
see [web-extensions](https://github.com/owncloud/web-extensions/blob/main/LICENSE)

```shell
container=$(docker run -d --entrypoint sleep --rm  owncloud/web-extensions:external-sites-0.3.0 10)
docker cp $container:/var/lib/nginx/html/unzip/manifest.json .
docker cp $container:/var/lib/nginx/html/unzip/external-sites.js .
```