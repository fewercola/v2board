## 使用 Docker Compose 部署

    git clone --depth 1 https://github.com/fewercola/v2board .
    docker compose pull
    docker compose run -it --rm v2board sh init.sh
    docker compose up -d

切记及时记录 密码 和 后台路径

网站默认端口 7002

mysql/mariadb需自行安装

## 使用 Docker Compose 更新 v2board

    docker compose run -it --rm v2board sh update.sh
    docker compose pull
    docker compose down
    docker compose run -it --rm v2board php artisan v2board:update
    docker compose up -d
