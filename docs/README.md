# Linux 迁移相关文档（PDF 转 Markdown）

本目录由 `scripts/pdf_to_md.py` 根据 `PDF_TO_MD_LIST.md` 从 PDF 转换而来，供其他 AI 或工具阅读以了解 ZYNQ AC820 Linux 迁移相关信息。

## 目录结构

- `*.md`：各文档的 Markdown 正文
- `images/`：提取的图片，命名格式 `文档名_页码_序号.png`
- MD 内图片引用为相对路径：`![描述](images/xxx.png)`

## 文档列表（按转换顺序）

| 文件 | 说明 |
|------|------|
| `04__Linux教程_基于Linux的嵌入式系统开发和应用教程V1_1.md` | Linux 教程 2020 版（最高优先级） |
| `04__Linux教程_基于Linux的嵌入式系统开发和应用教程V1_4.md` | Linux 教程 2018 版 |
| `01__用户手册_AC820开发板用户手册_Zynq7020_v1_1.md` | AC820 开发板用户手册 |
| `05_AC820-ZYNQ开发板QT环境构建手册V1_0_1.md` | QT 环境构建 |
| `第21章_基于ACM7606的多通道简易示波器.md` | ACM7606 示波器教程 |
| `RTL8211F-CG.md` | 以太网 PHY 芯片手册 |
| `c_ug1144-petalinux-tools-reference-guide.md` | PetaLinux 工具参考 |

## 重新转换

见项目根目录 `PDF_TO_MD_LIST.md` 中的「macOS 下转换说明」。
