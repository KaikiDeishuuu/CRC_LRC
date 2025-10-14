# 贡献指南

感谢你对 CRC/LRC 校验计算器项目感兴趣！我们欢迎所有形式的贡献。

## 📋 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发指南](#开发指南)
- [提交规范](#提交规范)
- [代码审查](#代码审查)

---

## 📜 行为准则

### 我们的承诺

为了营造开放和友好的环境，我们作为贡献者和维护者承诺：无论年龄、体型、残疾、民族、性别特征、性别认同和表达、经验水平、教育程度、社会经济地位、国籍、外貌、种族、宗教或性取向如何，参与我们的项目和社区都将是一种无骚扰的体验。

### 我们的标准

有助于创造积极环境的行为包括：

- ✅ 使用友好和包容的语言
- ✅ 尊重不同的观点和经验
- ✅ 优雅地接受建设性批评
- ✅ 关注对社区最有利的事情
- ✅ 对其他社区成员表现出同理心

不可接受的行为包括：

- ❌ 使用性暗示的语言或图像
- ❌ 挑衅、侮辱或贬损性评论，以及人身或政治攻击
- ❌ 公开或私下骚扰
- ❌ 未经明确许可发布他人的私人信息
- ❌ 在专业环境中被合理认为不适当的其他行为

---

## 🤝 如何贡献

### 报告 Bug

发现 Bug？请通过以下步骤报告：

1. **检查已有 Issues** - 确保该问题尚未被报告
2. **创建新 Issue** - 使用 Bug 报告模板
3. **提供详细信息**：
   - 操作系统和版本（如 Ubuntu 22.04）
   - Go 版本（运行 `go version`）
   - Node.js 和 Yarn 版本（如涉及前端）
   - 重现步骤
   - 期望行为
   - 实际行为
   - 错误日志或截图

**示例**：

```markdown
**环境**

- OS: Ubuntu 22.04
- Go: 1.21.5
- Docker: 24.0.7

**重现步骤**

1. 启动服务 `go run .`
2. 发送请求 `curl -X POST ...`
3. 观察错误

**期望行为**
应该返回正确的 CRC16 值

**实际行为**
返回 500 错误

**错误日志**
```

[ERROR] ...

```

```

### 建议新功能

有好想法？欢迎提出！

1. **创建 Feature Request Issue**
2. **描述功能**：
   - 功能概述
   - 使用场景和动机
   - 建议的实现方式（可选）
   - 是否愿意贡献代码

### 改进文档

文档改进也是重要的贡献！

- 修复错别字或语法错误
- 改进示例代码
- 添加使用场景
- 翻译文档（计划支持英文）

---

## 🛠️ 开发指南

### 环境设置

#### 后端开发

```bash
# 1. Fork 并克隆仓库
git clone https://github.com/YOUR_USERNAME/CRC_LRC.git
cd CRC_LRC

# 2. 安装 Go 1.21+
# 参考: https://go.dev/doc/install

# 3. 安装依赖
go mod download

# 4. 运行应用
go run .

# 5. 运行测试
go test ./...

# 6. 格式化代码
go fmt ./...
```

#### 前端开发

```bash
# 1. 进入前端目录
cd frontend

# 2. 安装依赖
yarn install

# 3. 开发模式（热重载）
yarn dev

# 4. 构建生产版本
yarn build
```

### 项目结构

```
CRC_LRC/
├── main.go                 # 入口文件
├── handler.go              # HTTP 处理器
├── config/                 # 配置
├── internal/
│   ├── calculator/        # 算法实现 ⭐ 添加新算法在这里
│   ├── handler/           # API 处理器
│   └── router/            # 路由配置
├── frontend/              # 前端源码
│   └── src/app.ts        # TypeScript 主文件 ⭐ 前端逻辑
└── web/                   # 编译后的前端
```

### 添加新算法

#### 步骤 1: 定义算法类型

编辑 `internal/calculator/types.go`：

```go
const (
    // ... 现有算法
    NewAlgorithm CRCType = "NEW_ALGORITHM" // 新算法名称
)
```

#### 步骤 2: 实现算法

编辑 `internal/calculator/calculator.go`：

```go
func calculateNewAlgorithm(data []byte) string {
    // 实现你的算法
    var result uint16
    // ... 计算逻辑
    return fmt.Sprintf("%04X", result)
}

// 在 Calculate 函数中添加分支
func (c *Calculator) Calculate(data []byte, crcType CRCType) (string, error) {
    switch crcType {
    // ... 现有分支
    case NewAlgorithm:
        return calculateNewAlgorithm(data), nil
    default:
        return "", fmt.Errorf("unsupported algorithm: %s", crcType)
    }
}
```

#### 步骤 3: 更新 API 处理器

编辑 `internal/handler/checksum_handler.go`：

```go
// 在响应结构中添加新字段
type ChecksumResponse struct {
    CRC           string `json:"crc"`
    CRC16CCITT    string `json:"crc16_ccitt"`
    CRC32         string `json:"crc32"`
    SUM8          string `json:"sum8"`
    NewAlgorithm  string `json:"new_algorithm"` // 新增
}

// 在处理函数中计算新算法
newAlgo, _ := calc.Calculate(dataBytes, calculator.NewAlgorithm)
response.NewAlgorithm = newAlgo
```

#### 步骤 4: 更新前端

编辑 `frontend/src/app.ts`：

```typescript
// 在结果显示中添加新算法
interface CalculationResult {
  type: string;
  value: string;
  description: string;
}

// 在 displayResults 函数中处理新算法
if (data.new_algorithm) {
  results.push({
    type: "NEW ALGORITHM",
    value: data.new_algorithm,
    description: "新算法描述",
  });
}
```

#### 步骤 5: 添加测试

创建 `internal/calculator/calculator_test.go`：

```go
func TestCalculateNewAlgorithm(t *testing.T) {
    calc := NewCalculator()
    data := []byte("Hello")

    result, err := calc.Calculate(data, NewAlgorithm)
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }

    expected := "XXXX" // 期望的结果
    if result != expected {
        t.Errorf("expected %s, got %s", expected, result)
    }
}
```

#### 步骤 6: 更新文档

- 在 `README.md` 的算法表格中添加新算法
- 在 `API_DOCUMENTATION.md` 中添加 API 示例
- 更新测试向量表

### 代码风格

#### Go 代码

```go
// ✅ 好的示例
func calculateCRC16(data []byte) uint16 {
    var crc uint16 = 0xFFFF

    for _, b := range data {
        crc ^= uint16(b)
        for i := 0; i < 8; i++ {
            if crc&1 != 0 {
                crc = (crc >> 1) ^ 0xA001
            } else {
                crc >>= 1
            }
        }
    }

    return crc
}

// ❌ 避免
func calc_crc(d []byte) uint16 { // 命名不规范
  var c uint16=0xFFFF // 缺少空格
  for _,b:=range d{ // 缺少空格
    c^=uint16(b)
    // ... 缺少注释
  }
  return c
}
```

#### TypeScript 代码

```typescript
// ✅ 好的示例
async function calculateChecksum(
  data: string,
  method: string
): Promise<ChecksumResult> {
  const response = await fetch("/api/checksum", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ data, method }),
  });

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return await response.json();
}

// ❌ 避免
function calc(d, m) {
  // 缺少类型注解
  return fetch("/api/checksum", {
    method: "POST",
    body: JSON.stringify({ d, m }), // 参数名不清晰
  }).then((r) => r.json()); // 缺少错误处理
}
```

### 运行测试

```bash
# 运行所有测试
go test ./...

# 运行特定包的测试
go test ./internal/calculator

# 运行测试并显示覆盖率
go test -cover ./...

# 生成覆盖率报告
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

---

## 📝 提交规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范。

### 提交消息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构（既不是新功能也不是 Bug 修复）
- `perf`: 性能优化
- `test`: 添加或修改测试
- `chore`: 构建过程或辅助工具的变动
- `ci`: CI/CD 配置
- `build`: 影响构建系统或外部依赖

### 示例

```bash
# 新功能
feat(calculator): add CRC64 algorithm support

# Bug 修复
fix(api): correct CRC16 MODBUS byte order

# 文档
docs(readme): update installation instructions

# 性能优化
perf(calculator): optimize CRC32 calculation

# 重构
refactor(handler): simplify error handling logic
```

### 提交内容

```bash
# ✅ 好的提交
feat(calculator): add CRC64 support

- Implement CRC64 ISO algorithm
- Add tests for standard test vectors
- Update API documentation
- Add frontend display for CRC64 results

Closes #123

# ❌ 避免
fix bug  # 太简单，缺少上下文
```

---

## 🔍 代码审查

### Pull Request 流程

1. **创建分支**

   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **开发并提交**

   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

3. **推送到你的 Fork**

   ```bash
   git push origin feature/my-new-feature
   ```

4. **创建 Pull Request**

   - 填写 PR 模板
   - 描述改动内容
   - 链接相关 Issue

5. **等待审查**
   - 维护者会审查你的代码
   - 根据反馈修改
   - 讨论并完善

### PR 检查清单

提交 PR 前请确认：

- [ ] 代码遵循项目风格指南
- [ ] 添加了必要的测试
- [ ] 所有测试通过 (`go test ./...`)
- [ ] 代码已格式化 (`go fmt ./...`)
- [ ] 更新了相关文档
- [ ] 提交消息符合规范
- [ ] 没有引入不必要的依赖
- [ ] 前端代码已构建 (`yarn build`)

### 审查标准

我们会检查：

- **功能正确性** - 是否按预期工作
- **代码质量** - 是否清晰、可维护
- **测试覆盖** - 是否有足够的测试
- **文档完整** - 是否更新了文档
- **性能影响** - 是否影响性能
- **向后兼容** - 是否破坏现有 API

---

## 🎯 优先级标签

Issues 和 PRs 会被标记：

- `good first issue` - 适合新手
- `help wanted` - 需要帮助
- `bug` - Bug 报告
- `enhancement` - 功能增强
- `documentation` - 文档相关
- `performance` - 性能优化
- `priority: high` - 高优先级
- `priority: low` - 低优先级

---

## 💡 寻求帮助

不确定从哪里开始？

1. 查看标记为 `good first issue` 的 Issues
2. 阅读现有代码了解项目结构
3. 在 Issue 中提问
4. 查看 [文档](./README.md)

---

## 📬 联系方式

- **GitHub Issues**: [提交 Issue](https://github.com/KaikiDeishuuu/CRC_LRC/issues)
- **GitHub Discussions**: [参与讨论](https://github.com/KaikiDeishuuu/CRC_LRC/discussions)
- **Pull Requests**: [提交 PR](https://github.com/KaikiDeishuuu/CRC_LRC/pulls)

---

## 🙏 感谢

感谢你考虑为本项目做出贡献！每一个贡献都很重要，无论大小。

---

**祝你编码愉快！** 🚀
