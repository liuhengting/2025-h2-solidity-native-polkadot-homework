#!/bin/bash
# 说明：脚本需在应用根目录下执行（cd 到部署目录后运行），${PWD} 对应应用根目录
# 核心调整：拆分两个进程的独立启动参数（eth-rpc 无 --tmp）

# ==================== 核心配置（按需修改，参数独立配置）====================
# 进程二进制路径（基于 ${PWD}）
BIN_DIR="${PWD}"
# 日志/PID目录（基于 ${PWD}）
LOG_DIR="${PWD}/logs"

# 进程配置：名称 日志文件 PID文件 独立启动参数（关键：各自的--参数分开写）
processes=(
  # substrate-node：带 --dev --tmp，用默认端口
  "substrate-node logs/substrate-node.log logs/substrate-node-pid.txt --dev --tmp"
  # eth-rpc：无 --tmp，仅保留需要的参数，用默认端口
  "eth-rpc logs/eth-rpc.log logs/eth-rpc-pid.txt --dev"
)
# 注：eth-rpc 的参数可按需调整（比如去掉 --dev 或添加其他参数），直接修改上面的启动参数部分即可
# ===========================================================================

# 工具函数：日志输出（带时间戳）
info() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $*"
}

# 工具函数：错误输出并退出
error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2
  exit 1
}

# 1. 检查二进制文件是否存在（避免路径错误）
if [ ! -x "${BIN_DIR}" ]; then
  error "二进制文件不存在或无执行权限！路径：${BIN_DIR}"
  error "请确认：1. 已cd到应用根目录；2. release/substrate-node 已编译且有执行权限（chmod +x 该文件）"
fi

# 2. 检查并创建 logs 目录（避免目录不存在导致失败）
if [ ! -d "${LOG_DIR}" ]; then
  info "logs 目录不存在，创建中：${LOG_DIR}"
  mkdir -p "${LOG_DIR}" || error "创建 logs 目录失败！请检查当前目录权限：${PWD}"
fi

# 3. 循环处理每个进程（清空文件 + 启动 + 校验）
for process in "${processes[@]}"; do
  # 解析配置：名称、日志文件、PID文件、独立启动参数（参数可能含空格，用 read -r 完整读取）
  read -r name log_file pid_file args <<< "${process}"
  # 拼接绝对路径（基于 ${PWD}，保证部署目录下的路径正确性）
  abs_log="${LOG_DIR}/$(basename "${log_file}")"
  abs_pid="${LOG_DIR}/$(basename "${pid_file}")"

  info "开始处理进程：${name}"

  # 4. 防重复启动（避免重复执行脚本导致冲突）
  if [ -f "${abs_pid}" ]; then
    existing_pid=$(cat "${abs_pid}" 2>/dev/null)
    if ps -p "${existing_pid}" &>/dev/null; then
      error "进程 ${name} 已在运行（PID: ${existing_pid}），请先停止再启动！"
    else
      info "PID文件 ${abs_pid} 存在但进程已退出，覆盖旧文件"
    fi
  fi

  # 5. 清空日志/PID文件（truncate 不存在则创建空文件）
  info "清空文件：${abs_log}、${abs_pid}"
  truncate -s 0 "${abs_log}" || error "清空日志失败！请检查权限：${abs_log}"
  truncate -s 0 "${abs_pid}" || error "清空PID文件失败！请检查权限：${abs_pid}"

  # 6. 后台启动进程（核心修正：使用每个进程的独立参数，不共用 --tmp）
  info "启动命令：setsid ${BIN_DIR} ${args} >> ${abs_log} 2>&1 &"
  setsid "${BIN_DIR}/${name}" ${args} >> "${abs_log}" 2>&1 &
  pid=$!

  # 7. 校验进程是否启动成功（避免无效PID）
  sleep 1
  if ps -p "${pid}" &>/dev/null; then
    info "进程 ${name} 启动成功（PID: ${pid}），日志：${abs_log}"
    echo "${pid}" > "${abs_pid}" || error "写入PID文件失败！请检查权限：${abs_pid}"
  else
    error "进程 ${name} 启动失败！请查看日志排查：${abs_log}"
    error "可能原因：启动参数错误（当前参数：${args}）、端口被占用、二进制文件异常"
  fi

  info "进程 ${name} 处理完成\n"
done

info "所有进程启动完成！"
info "日志目录：${LOG_DIR}"
