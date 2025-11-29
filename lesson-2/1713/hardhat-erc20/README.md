## 配置和部署流程

### 1. 环境准备

项目依赖于Polkadot生态中的两个核心组件：
- substrate-node: 提供底层区块链功能
- eth-rpc: 提供以太坊RPC接口，使EVM兼容

这些组件通过[start.sh](./start.sh)脚本进行管理和启动。

### 2. 启动本地开发链

使用以下命令启动本地Polkadot EVM兼容链：

```bash
# 在substrate-node同目录下运行
./start.sh
```

### 3. 配置hardhat.config.ts

hardhat.config.ts里的networks里添加如下配置(参考初始化时附带的配置)

``` typescript
    localhost: {
      type: "http",
      chainType: "l1",
      url: 'http://127.0.0.1:8545',
      accounts: [configVariable("LOCALHOST_PRIVATE_KEY")],
    },
```

### 4. 配置 keystore

```shell
# 创建keystore
# 初次创建时，需要设置Keystore密码
# 后续set和get时，都需要输入密码才能执行后续操作
pnpm hardhat keystore set LOCALHOST_PRIVATE_KEY --dev
```

### 5. 执行hardhat测试
```shell
pnpm hardhat test test/MyToken.ts --network localhost
```