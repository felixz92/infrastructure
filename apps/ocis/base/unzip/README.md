# unzip 

see [web-extensions](https://github.com/owncloud/web-extensions/tree/main/packages/web-app-unzip)

Copied from running container since the web-extensions containers do not support arm64 at the moment.

```shell
container=$(docker run -d --entrypoint sleep --rm  owncloud/web-extensions:unzip-0.4.0 10)
docker cp $container:/var/lib/nginx/html/unzip .

```