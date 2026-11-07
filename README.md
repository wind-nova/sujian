# 素笺 SuJian · Flutter App

> 把冰凉的数字文字，落回有纹理的纸与有呼吸的墨。

Android 手机端实现。设计规范见上一级目录 [素笺SuJian-UI设计规范.md](../素笺SuJian-UI设计规范.md)，
可交互 Web 原型见 [sujian-ui.html](../sujian-ui.html)。

---

## 一、云打包（推荐，无需本机装 Flutter）

### 方式 A · GitHub Actions

1. 把本目录作为一个仓库推上去（`android/` 不用提交，构建时自动生成）：

```bash
cd 素笺SuJian/app
git init && git add . && git commit -m "素笺 v1.0"
git remote add origin git@github.com:<你的账号>/sujian.git
git push -u origin main
```

2. GitHub 仓库页 → **Actions** → 左侧 `build-apk` → **Run workflow**。
3. 约 6–10 分钟，在本次运行的 **Artifacts** 里下载 `sujian-apk.zip`，内含 3 个按 ABI 拆分的 APK：
   - `app-arm64-v8a-release.apk` ← 绝大多数手机装这个
   - `app-armeabi-v7a-release.apk` ← 老设备
   - `app-x86_64-release.apk` ← 模拟器

### 方式 B · Codemagic / 其他云构建

构建命令直接指向脚本即可，它会自己生成 `android/` 平台目录：

```bash
chmod +x tool/cloud_build.sh && ./tool/cloud_build.sh
```

> **为什么仓库里没有 `android/`？**
> 平台目录是 Flutter 的模板产物（几十个文件、随 SDK 版本变化）。
> 构建时用 `flutter create --platforms=android .` 现场生成，再 `git checkout -- lib pubspec.yaml`
> 把被模板覆盖掉的源码还原，最后覆盖我们自己的 `AndroidManifest.xml`。
> 好处是仓库里只剩"真正的资产"，换 Flutter 版本也不会积累奇怪的 diff。

---

## 二、本机构建（装了 Flutter 之后）

```bash
flutter --version          # 需要 3.24+
flutter pub get
chmod +x tool/cloud_build.sh && ./tool/cloud_build.sh
# 或者手动：
flutter create --org com.sujian --project-name sujian --platforms=android .
cp tool/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
flutter build apk --release
```

调试运行：`flutter run --release`

---

## 三、代码结构

```
lib/
├─ main.dart                入口：初始化纸纹、锁定文字缩放
├─ theme.dart               设计令牌（颜色 / 阴影 / 环境光）
├─ model.dart               PageDoc（不可变）+ 5 纸 / 5 笔迹 / 3 墨
├─ render/                  ← 核心，与 UI 完全解耦
│  ├─ rng.dart              FNV-1a + mulberry32（确定性抖动）
│  ├─ texture.dart          190×190 噪声平铺（纸纹颗粒）
│  ├─ ornaments.dart        图钉 / 小红花
│  ├─ paper_painter.dart    L1 纸基 + L2 印刷 + L4 光照 + L5 装饰
│  ├─ ink_painter.dart      L3 墨：逐字变换 + 两遍晕染合成
│  ├─ scene.dart            一张纸 = 缓存的纸层 + 实时的墨层
│  └─ exporter.dart         离屏渲染 → PNG / 多页 PDF
├─ pages/
│  ├─ home_page.dart        首页（空白信纸）
│  ├─ editor_page.dart      编辑与生成（预览 + 下沉参数抽屉）
│  └─ result_page.dart      结果与导出（印章 / 保存 / PDF / 分享）
└─ widgets/hand_button.dart 手绘椭圆按钮 + 手绘图标集
```

### 三个关键实现点

**1. 分层渲染，只有墨层重绘**

```dart
Stack(children: [
  RepaintBoundary(child: CustomPaint(painter: PaperPainter(...))),  // 换纸才重绘
  CustomPaint(painter: InkPainter(doc)),                            // 参数变化只重绘这层
])
```

**2. 排版与抖动解耦（拖滑块不重排）**

逐字位置用**名义字距**（`fontPx * 0.04`）累加，随机量只在绘制阶段施加、不反馈给游标。
所以拖动「真实感」时文字纹丝不动，只有倾斜/抖动/晕染在变——像拧对焦环，不像重打一遍。

**3. 晕染整层做，不逐字做**

```dart
canvas.saveLayer(rect, Paint()
  ..blendMode = BlendMode.multiply
  ..color = Color(0x80000000)
  ..imageFilter = ImageFilter.blur(sigmaX: bleed, sigmaY: bleed));
canvas.drawPicture(pic);   // ① 墨洇进纤维
canvas.restore();
canvas.saveLayer(rect, Paint()..blendMode = BlendMode.multiply);
canvas.drawPicture(pic);   // ② 实笔压在纸上
canvas.restore();
```

每个字设一次 `filter` 就等于一次 SaveLayer，1500 个字直接把 GPU 打满——
所以先录成 `Picture` 再整层模糊一次，重放几乎零成本。

---

## 四、字体

5 档笔迹全部为可商用字库，均已子集化到 **GB2312 一级汉字全集（3755 字）+ 符号区**，
共 4607 个字符——足够覆盖日常书写 99.7% 的用字，不会出现"某个字突然换了字体"的破功：

| 档位 | 字库 | 授权 | 子集体积 |
|---|---|---|---|
| 日常（默认） | KaiXinJiuXiaoLinYuJiuZou | 需确认（见规范 §9） | 1.8 MB |
| 娟秀 | Ma Shan Zheng 马善政 | SIL OFL 1.1 | 2.9 MB |
| 行楷 | Zhi Mang Xing 志莽行书 | SIL OFL 1.1 | 2.1 MB |
| 工整 | Long Cang 龙藏 | SIL OFL 1.1 | 2.6 MB |
| 少女 | ZCOOL KuaiLe 站酷快乐体 | SIL OFL 1.1 | 0.7 MB |

合计 10 MB，APK 约 32 MB。

重新生成（改字库、改字符集后）：

```bash
python ../build/build_app_fonts.py
```

> 脚本会自动下载 OFL 字库（走 jsDelivr 镜像）、枚举 GB2312 字符集、子集化，
> 输出到 `assets/fonts/`。字库源文件不入库（见 `.gitignore`）。
>
> **上线前必做**：把「日常」档的 KaiXin 字体换成已取得**商用 + 嵌入 App** 书面许可的版本；
> 未确认前建议默认档临时改用 OFL 的霞鹜文楷。


---

## 五、已知边界

- 超过一页的长文会自动分页：预览里点页码翻页，PDF 导出全部分页。
- 「保存图片」走 MediaStore，**Android 10+ 不申请任何权限**；Android 9 及以下才要写外部存储。
- 分享用系统面板（微信里一样能选"朋友圈"），v1.0 不接微信 SDK。
- PDF 为位图方案（2000px 宽，约 700 KB/页）；矢量文字方案见规范 §6.10。
