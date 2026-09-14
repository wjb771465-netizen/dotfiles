#!/usr/bin/env python3
"""Fill a group-meeting deck from a reviewed session.md draft.

Degraded workflow: this script does NOT try to lay out the slide. It dumps the
page text into ONE body textbox (title box + footers come from the template)
using a fixed preset format (微软雅黑 20pt, 1.25 line spacing), turns **...**
markers into real bold runs, and drops referenced images as pictures at a
default spot. The human does the final layout in PowerPoint.

Usage:
    fill_deck.py <output.pptx> <session.md>

Rebuilds the deck from the DUT template each run, so re-running overwrites the
output. Do your layout tweaks in PowerPoint after the LAST fill run.
"""
import copy
import re
import sys
from pathlib import Path

from pptx import Presentation
from pptx.util import Pt, Emu
from pptx.oxml.ns import qn

# ---- preset format constants (single place to tune) ------------------------
FONT = "微软雅黑"
BODY_SIZE = 20          # pt
TITLE_SIZE = 28         # pt (template 文本框 4)
FOOTER_SIZE = 10.5      # pt
LINE_SPACING = 125000   # 1.25x  (OOXML spcPct)
SPACING_AFTER = 600     # 6 pt   (OOXML spcPts *100)
BULLET_CHAR = "•"
BULLET_FONT = "Arial"

SKILL = Path(__file__).resolve().parent.parent
TEMPLATE = SKILL / "ppt" / "组会模版.pptx"
COVER_TITLE = "封面"
BODY_NAME = "文本框 1"
TITLE_NAME = "文本框 4"
FOOTER_DATE_NAME = "FooterDate"
FOOTER_PAGE_NAME = "FooterPage"
# content slide used as the template for every page (slide 2 = "上周工作")
CONTENT_INDEX = 1

# picture default placement (human repositions afterwards)
IMG_WIDTH_FRAC = 0.40   # of slide width
IMG_MIN_Y = Emu(4600000)  # below body text

# default content-area position of the body textbox (manually tuned once)
BODY_LEFT = Emu(1533896)
BODY_TOP = Emu(1259472)


def find_shape(slide, name):
    for sh in slide.shapes:
        if sh.name == name:
            return sh
    return None


def set_para(para, text, *, bullet=False, level=0, size=BODY_SIZE, bold=False, font=None):
    """Apply the preset format to a paragraph and add run(s), parsing **b**."""
    pPr = para._p.get_or_add_pPr()
    # rebuild child elements from scratch so ordering follows the OOXML schema
    # (the template's first paragraph leaves a residual <a:buClrTx/> that would
    # precede <a:lnSpc> and trigger PowerPoint's repair prompt).
    for child in list(pPr):
        pPr.remove(child)
    pPr.set("algn", "l")
    pPr.set("marL", "228600")
    pPr.set("indent", "-228600")

    ln = pPr.makeelement(qn("a:lnSpc"), {})
    ln.append(pPr.makeelement(qn("a:spcPct"), {"val": str(LINE_SPACING)}))
    pPr.append(ln)
    aft = pPr.makeelement(qn("a:spcAft"), {})
    aft.append(pPr.makeelement(qn("a:spcPts"), {"val": str(SPACING_AFTER)}))
    pPr.append(aft)

    if bullet:
        pPr.append(pPr.makeelement(qn("a:buFont"), {"typeface": BULLET_FONT}))
        pPr.append(pPr.makeelement(qn("a:buChar"), {"char": BULLET_CHAR}))
    else:
        pPr.append(pPr.makeelement(qn("a:buNone"), {}))

    for part in re.split(r"(\*\*.+?\*\*)", text):
        if not part:
            continue
        b = bold
        t = part
        if part.startswith("**") and part.endswith("**"):
            b = True
            t = part[2:-2]
        run = para.add_run()
        run.text = t
        run.font.size = Pt(size)
        run.font.name = font or FONT
        run.font.bold = b


def fill_textbox(tf, lines):
    """lines: iterable of parsed items; item[0] is 'text'|'bullet'|'image'."""
    tf.clear()
    for i, item in enumerate(lines):
        para = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        if item[0] == "bullet":
            _, level, text = item
            set_para(para, text, bullet=True, level=level, size=BODY_SIZE)
        else:
            set_para(para, item[1], size=BODY_SIZE)


def set_cover_date(slide, date):
    sh = find_shape(slide, "CustomShape 4")
    if sh is None:
        print("  ! cover date shape (CustomShape 4) not found; skipped")
        return
    tf = sh.text_frame
    tf.clear()
    set_para(tf.paragraphs[0], date, size=20)


def set_footer(slide, date, page):
    d = find_shape(slide, FOOTER_DATE_NAME)
    p = find_shape(slide, FOOTER_PAGE_NAME)
    if d is not None:
        d.text_frame.clear()
        set_para(d.text_frame.paragraphs[0], date, size=FOOTER_SIZE, bold=True, font="Arial")
    if p is not None:
        p.text_frame.clear()
        set_para(p.text_frame.paragraphs[0], str(page), size=FOOTER_SIZE, bold=True, font="Arial")


def _dup(slide, prs):
    """Copy a slide onto a fresh slide that uses the source's own layout.
    The source's slideLayout and notesSlide rels are NOT copied: add_slide()
    already creates the (single) correct slideLayout rel, and copying it would
    give the slide two slideLayout relationships — which PowerPoint rejects
    with a 'content problem' repair prompt."""
    dest = prs.slides.add_slide(slide.slide_layout)
    for shp in list(dest.shapes):
        shp._element.getparent().remove(shp._element)
    for shp in slide.shapes:
        dest.shapes._spTree.append(copy.deepcopy(shp._element))
    for rel in slide.part.rels.values():
        if rel.reltype.endswith("/notesSlide") or rel.reltype.endswith("/slideLayout"):
            continue
        if rel.is_external:
            dest.part.rels.get_or_add_ext_rel(rel.reltype, rel.target_ref)
        else:
            dest.part.rels.get_or_add(rel.reltype, rel.target_part)
    return dest


def delete_slide(prs, index):
    sldIdLst = prs.slides._sldIdLst
    ids = list(sldIdLst)
    sid = ids[index]
    rId = sid.get(qn("r:id"))
    prs.part.drop_rel(rId)
    sldIdLst.remove(sid)


def parse_md(path):
    """Return (date, [pages]); pages = (title, [lines]) with lines =
    (kind, payload). kind: 'text'|'bullet'|'image'. Image payload = (path, alt)."""
    text = Path(path).read_text(encoding="utf-8")
    pages = []
    cur_title = None
    cur_lines = []
    date = None

    def flush():
        if cur_title is not None:
            pages.append((cur_title, cur_lines))

    for raw in text.splitlines():
        m = re.match(r"^##\s+(.*)", raw)
        if m:
            flush()
            cur_title = m.group(1).strip()
            cur_lines = []
            continue
        if cur_title is None:
            continue
        if not raw.strip():
            continue
        line = raw.rstrip("\n")
        bm = re.match(r"^(\s*)[-*•]\s+(.*)$", line)
        if bm:
            level = 1 if len(bm.group(1).replace("\t", "  ")) >= 2 else 0
            cur_lines.append(("bullet", level, bm.group(2)))
            continue
        im = re.match(r"^!\[(.*?)\]\((.*?)\)\s*$", line.strip())
        if im:
            cur_lines.append(("image", im.group(2), im.group(1)))
            continue
        cur_lines.append(("text", line))
    flush()

    # derive date from cover block
    for title, lines in pages:
        if title == COVER_TITLE:
            for kind, payload in lines:
                if kind == "text":
                    date = payload.strip()
                    break
            break
    return date, pages


def add_picture(slide, path, prs_w):
    from PIL import Image
    img_path = Path(path)
    if not img_path.is_file():
        print(f"  ! image not found: {path}")
        return
    with Image.open(img_path) as im:
        pw, ph = im.size
    max_w = int(prs_w * IMG_WIDTH_FRAC)
    max_h = int(prs_w * 0.4)  # also cap height for tall figures
    w = max_w
    h = int(w * ph / pw)
    if h > max_h:
        h = max_h
        w = int(h * pw / ph)
    left = int((prs_w - w) / 2)
    slide.shapes.add_picture(str(img_path), left, IMG_MIN_Y, width=Emu(w), height=Emu(h))


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    out = Path(sys.argv[1])
    md = Path(sys.argv[2])

    date, pages = parse_md(md)
    content_pages = [(t, l) for t, l in pages if t != COVER_TITLE]
    print(f"parsed {len(pages)} page(s): cover{' ' + date if date else ''}, "
          f"{len(content_pages)} content page(s)")

    if not TEMPLATE.is_file():
        print(f"template not found: {TEMPLATE}"); sys.exit(1)

    prs = Presentation(str(TEMPLATE))
    src = prs.slides[CONTENT_INDEX]   # template content slide

    # cover date
    if date:
        set_cover_date(prs.slides[0], date)

    # build content pages
    new_slides = []
    for title, lines in content_pages:
        dest = _dup(src, prs)
        new_slides.append(dest)

        tsh = find_shape(dest, TITLE_NAME)
        bsh = find_shape(dest, BODY_NAME)
        if tsh is None or bsh is None:
            print(f"  ! title/body box not found for '{title}'; skipped"); continue

        tsh.text_frame.clear()
        set_para(tsh.text_frame.paragraphs[0], title, size=TITLE_SIZE, bold=True)

        # reposition body box to the default content area (same as manual tuning)
        body_lines = [l for l in lines if l[0] != "image"]
        bsh.left = BODY_LEFT
        bsh.top = BODY_TOP
        bsh.width = prs.slide_width - tsh.left - Emu(200000)
        has_img = any(l[0] == "image" for l in lines)
        bsh.height = Emu(4200000) if has_img else Emu(5000000)

        fill_textbox(bsh.text_frame, body_lines)

        # images (paths resolved relative to the session.md directory)
        for l in lines:
            if l[0] == "image":
                _, imgpath, alt = l
                p = Path(imgpath)
                if not p.is_absolute():
                    p = md.parent / p
                add_picture(dest, str(p), prs.slide_width)

        set_footer(dest, date or "YYYY.MM.DD", 0)  # page set later

    # drop the template's example content slides (slide 2 & 3) that we copied from
    delete_slide(prs, 1)
    delete_slide(prs, 1)

    # renumber footers
    for i, slide in enumerate(prs.slides):
        if i == 0:
            continue
        set_footer(slide, date or "YYYY.MM.DD", i + 1)

    out.parent.mkdir(parents=True, exist_ok=True)
    prs.save(str(out))
    print(f"saved {out}")


if __name__ == "__main__":
    main()
