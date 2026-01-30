#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将 PDF 转为 Markdown + images/*.png 图文混排格式。
使用方式（建议用系统 Python，避免 atopile 等虚拟环境干扰）：
  /opt/homebrew/bin/python3 scripts/pdf_to_md.py
  或
  python3 scripts/pdf_to_md.py --pdf "/Volumes/ZYNQ/01_文档教材/04_Linux应用教程/ZYNQ/2020版本/04_【Linux教程】基于Linux的嵌入式系统开发和应用教程V1_1.pdf"
可指定多个 --pdf，或使用 --list 从 PDF_TO_MD_LIST.md 解析路径。
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

try:
    import fitz  # pymupdf
except ImportError:
    print("请先安装 pymupdf: pip3 install pymupdf", file=sys.stderr)
    sys.exit(1)

# 默认：ZYNQ 映射盘根路径、输出目录
ZYNQ_BASE = os.environ.get("ZYNQ_BASE", "/Volumes/ZYNQ")
OUTPUT_DIR = os.environ.get("PDF2MD_OUTPUT", "docs")
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent


def sanitize_basename(name: str) -> str:
    """生成用于文件名/目录名的安全短名称。"""
    # 去掉 .pdf 与路径
    base = Path(name).stem
    # 只保留字母数字、下划线、中文（保留）
    base = re.sub(r"[^\w\u4e00-\u9fff\-]", "_", base)
    return base[:80] if len(base) > 80 else base


def extract_pdf_to_md(
    pdf_path: str,
    out_md_path: str,
    out_images_dir: str,
    base_name: str,
) -> bool:
    """将单个 PDF 转为 MD + images/*.png，图文按版面顺序混排。"""
    pdf_path = os.path.abspath(pdf_path)
    if not os.path.isfile(pdf_path):
        print(f"  [跳过] 文件不存在: {pdf_path}", file=sys.stderr)
        return False

    os.makedirs(out_images_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    md_lines = [f"# {base_name}\n", f"*来源 PDF: `{os.path.basename(pdf_path)}`*\n\n---\n\n"]

    try:
        for page_num in range(len(doc)):
            page = doc[page_num]
            page_content = []  # (y0, "text"|"image", payload)

            # 文本块（带位置）
            blocks = page.get_text("dict", sort=True)["blocks"]
            for block in blocks:
                for line in block.get("lines", []):
                    for span in line.get("spans", []):
                        text = span.get("text", "").strip()
                        if not text:
                            continue
                        bbox = span.get("bbox", (0, 0, 0, 0))
                        y0 = bbox[1]
                        page_content.append((y0, "text", text))

            # 本页图片（带位置）
            img_list = page.get_images(full=True)
            for img_idx, (xref, *_ ) in enumerate(img_list):
                try:
                    rects = page.get_image_rects(xref)
                    if not rects:
                        rects = [page.rect]
                    y0 = min(r.y0 for r in rects)
                    page_content.append((y0, "image", (xref, img_idx, page_num + 1)))
                except Exception:
                    continue

            page_content.sort(key=lambda x: (x[0], 0 if x[1] == "text" else 1))

            img_counter = 0
            for _, kind, payload in page_content:
                if kind == "text":
                    md_lines.append(payload + "\n\n")
                else:
                    xref, img_idx, pnum = payload
                    img_counter += 1
                    img_name = f"{base_name}_{pnum:02d}_{img_counter:02d}.png"
                    img_path = os.path.join(out_images_dir, img_name)
                    try:
                        pix = fitz.Pixmap(doc, xref)
                        if pix.n - pix.alpha > 3:
                            pix = fitz.Pixmap(fitz.csRGB, pix)
                        pix.save(img_path)
                        pix = None
                    except Exception as e:
                        print(f"  [警告] 无法保存图片 {img_name}: {e}", file=sys.stderr)
                        continue
                    rel_path = os.path.join("images", img_name)
                    md_lines.append(f"![{base_name} 第{pnum}页 图{img_counter}]({rel_path})\n\n")

            # 每页后加分页提示（可选）
            if page_num < len(doc) - 1:
                md_lines.append("\n---\n*下一页*\n\n")

    finally:
        doc.close()

    with open(out_md_path, "w", encoding="utf-8") as f:
        f.writelines(md_lines)

    print(f"  [完成] {out_md_path} + {out_images_dir}")
    return True


def parse_list_file(list_path: str, zynq_base: str) -> list[str]:
    """从 PDF_TO_MD_LIST.md 中解析出 PDF 相对路径并转为绝对路径。"""
    with open(list_path, "r", encoding="utf-8") as f:
        content = f.read()
    # 匹配 "- **文件路径**: `...pdf`"
    pattern = r"-\s*\*\*文件路径\*\*:\s*`([^`]+\.pdf)`"
    rel_paths = re.findall(pattern, content, re.IGNORECASE)
    # 去重并保持顺序
    seen = set()
    out = []
    for rel in rel_paths:
        rel = rel.strip()
        if rel.lower().endswith(".pdf") and rel not in seen:
            seen.add(rel)
            full = os.path.join(zynq_base, rel)
            out.append(full)
    return out


def main():
    parser = argparse.ArgumentParser(description="PDF 转 Markdown + images/*.png")
    parser.add_argument("--pdf", action="append", default=[], help="PDF 绝对路径，可多次指定")
    parser.add_argument("--list", action="store_true", help="从 PDF_TO_MD_LIST.md 解析路径（相对 ZYNQ 根）")
    parser.add_argument("--zynq-base", default=ZYNQ_BASE, help=f"ZYNQ 根路径，默认 {ZYNQ_BASE}")
    parser.add_argument("--output-dir", default=OUTPUT_DIR, help=f"输出目录（相对项目根），默认 {OUTPUT_DIR}")
    args = parser.parse_args()

    pdfs = list(args.pdf)
    if args.list:
        list_file = PROJECT_ROOT / "PDF_TO_MD_LIST.md"
        if not list_file.is_file():
            print(f"未找到列表文件: {list_file}", file=sys.stderr)
            sys.exit(1)
        pdfs = parse_list_file(str(list_file), args.zynq_base)
        print(f"从 PDF_TO_MD_LIST.md 解析到 {len(pdfs)} 个 PDF")

    if not pdfs:
        print("未指定任何 PDF，使用 --pdf 或 --list", file=sys.stderr)
        sys.exit(1)

    out_root = PROJECT_ROOT / args.output_dir
    out_root.mkdir(parents=True, exist_ok=True)
    images_dir = out_root / "images"
    images_dir.mkdir(parents=True, exist_ok=True)

    ok = 0
    for pdf in pdfs:
        base_name = sanitize_basename(pdf)
        out_md = out_root / f"{base_name}.md"
        # 所有图片放在同一 images/ 目录，命名：文件名_页码_序号.png
        if extract_pdf_to_md(pdf, str(out_md), str(images_dir), base_name):
            ok += 1

    print(f"\n共处理 {len(pdfs)} 个，成功 {ok} 个。输出目录: {out_root}")


if __name__ == "__main__":
    main()
