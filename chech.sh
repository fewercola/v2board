#!/bin/bash

echo "========== V2Board 流量统计诊断 =========="
echo ""

# 1. 检查Redis连接
echo "1. 检查Redis连接..."
php -r "
require __DIR__.'/vendor/autoload.php';
\$app = require_once __DIR__.'/bootstrap/app.php';
\$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
try {
    \$redis = \Illuminate\Support\Facades\Redis::connection();
    \$redis->ping();
    echo '✓ Redis连接正常' . PHP_EOL;

    // 检查流量数据
    \$upload = \$redis->hlen('v2board_upload_traffic');
    \$download = \$redis->hlen('v2board_download_traffic');
    echo \"  - 上传流量记录数: \$upload\" . PHP_EOL;
    echo \"  - 下载流量记录数: \$download\" . PHP_EOL;
} catch (Exception \$e) {
    echo '✗ Redis连接失败: ' . \$e->getMessage() . PHP_EOL;
}
"
echo ""

# 2. 检查队列进程
echo "2. 检查队列进程..."
QUEUE_PROCESS=$(ps aux | grep -E "queue:work|horizon" | grep -v grep)
if [ -z "$QUEUE_PROCESS" ]; then
    echo "✗ 队列进程未运行"
else
    echo "✓ 队列进程运行中:"
    echo "$QUEUE_PROCESS"
fi
echo ""

# 3. 检查定时任务
echo "3. 检查定时任务..."
CRON_JOB=$(crontab -l 2>/dev/null | grep "schedule:run")
if [ -z "$CRON_JOB" ]; then
    echo "✗ 定时任务未配置"
else
    echo "✓ 定时任务已配置:"
    echo "$CRON_JOB"
fi
echo ""

# 4. 检查数据库流量记录
echo "4. 检查数据库流量记录..."
php -r "
require __DIR__.'/vendor/autoload.php';
\$app = require_once __DIR__.'/bootstrap/app.php';
\$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

\$userCount = \App\Models\User::where('u', '>', 0)->orWhere('d', '>', 0)->count();
echo \"  - 有流量记录的用户数: \$userCount\" . PHP_EOL;

\$statCount = \App\Models\StatUser::where('record_at', '>=', strtotime(date('Y-m-d')))->count();
echo \"  - 今日统计记录数: \$statCount\" . PHP_EOL;
"
echo ""

# 5. 检查失败的队列任务
echo "5. 检查失败的队列任务..."
php artisan queue:failed --format=json 2>/dev/null | head -5
echo ""

echo "========== 诊断完成 =========="
