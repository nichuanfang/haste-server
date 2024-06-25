# 第一阶段：构建依赖项和编译应用程序
FROM node:16-stretch AS build
WORKDIR /usr/src/app

# 复制 package.json 和 package-lock.json 到工作目录
COPY package*.json ./

# 安装 npm 依赖项，包括特定版本的 redis, pg, memcached, aws-sdk 和 rethinkdbdash
RUN npm install \
    && npm install redis@0.8.1 \
    && npm install pg@8.11.3 \
    && npm install memcached@2.2.2 \
    && npm install aws-sdk@2.814.0 \
    && npm install rethinkdbdash@2.3.31

# 复制应用程序源代码到工作目录
COPY . .

# 第二阶段：构建最终镜像
FROM node:16-stretch-slim
WORKDIR /usr/src/app

# 从第一阶段复制依赖项和已编译的应用程序代码
COPY --from=build /usr/src/app .

# 设置环境变量
ENV STORAGE_TYPE=memcached \
    STORAGE_HOST=127.0.0.1 \
    STORAGE_PORT=11211 \
    STORAGE_EXPIRE_SECONDS=2592000 \
    STORAGE_DB=2 \
    STORAGE_AWS_BUCKET= \
    STORAGE_AWS_REGION= \
    STORAGE_USERNAME= \
    STORAGE_PASSWORD= \
    STORAGE_FILEPATH= \
    LOGGING_LEVEL=verbose \
    LOGGING_TYPE=Console \
    LOGGING_COLORIZE=true \
    HOST=0.0.0.0 \
    PORT=7777 \
    KEY_LENGTH=10 \
    MAX_LENGTH=400000 \
    STATIC_MAX_AGE=86400 \
    RECOMPRESS_STATIC_ASSETS=true \
    KEYGENERATOR_TYPE=phonetic \
    KEYGENERATOR_KEYSPACE= \
    RATELIMITS_NORMAL_TOTAL_REQUESTS=500 \
    RATELIMITS_NORMAL_EVERY_MILLISECONDS=60000 \
    RATELIMITS_WHITELIST_TOTAL_REQUESTS= \
    RATELIMITS_WHITELIST_EVERY_MILLISECONDS= \
    RATELIMITS_WHITELIST=example1.whitelist,example2.whitelist \
    RATELIMITS_BLACKLIST_TOTAL_REQUESTS= \
    RATELIMITS_BLACKLIST_EVERY_MILLISECONDS= \
    RATELIMITS_BLACKLIST=example1.blacklist,example2.blacklist \
    DOCUMENTS=about=./about.md

# 暴露端口
EXPOSE ${PORT}

# 设置停止信号
STOPSIGNAL SIGINT

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD [ "sh", "-c", "echo -n 'curl localhost:7777... '; \
    (curl -sf localhost:7777 > /dev/null) && echo OK || (echo Fail && exit 2)" ]

# 入口点和默认命令
ENTRYPOINT [ "bash", "docker-entrypoint.sh" ]
CMD ["npm", "start"]
