from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape
import zipfile


OUT = Path("presentations/temtseenii_negdsen_platform.pptx")

SLIDE_W = 12192000
SLIDE_H = 6858000

NS = (
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
    'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"'
)


def emu(x: float) -> int:
    return int(x * 914400)


def text_box(
    shape_id: int,
    x: float,
    y: float,
    w: float,
    h: float,
    text: str,
    size: int,
    color: str = "FFFFFF",
    bold: bool = False,
    name: str = "Text",
) -> str:
    bold_attr = ' b="1"' if bold else ""
    lines = text.split("\n")
    paragraphs = []
    for line in lines:
        paragraphs.append(
            f"""
            <a:p>
              <a:r>
                <a:rPr lang="mn-MN" sz="{size}"{bold_attr}>
                  <a:solidFill><a:srgbClr val="{color}"/></a:solidFill>
                  <a:latin typeface="Aptos"/>
                  <a:cs typeface="Arial"/>
                </a:rPr>
                <a:t>{escape(line)}</a:t>
              </a:r>
              <a:endParaRPr lang="mn-MN" sz="{size}"/>
            </a:p>
            """
        )
    return f"""
    <p:sp>
      <p:nvSpPr>
        <p:cNvPr id="{shape_id}" name="{escape(name)}"/>
        <p:cNvSpPr txBox="1"/>
        <p:nvPr/>
      </p:nvSpPr>
      <p:spPr>
        <a:xfrm>
          <a:off x="{emu(x)}" y="{emu(y)}"/>
          <a:ext cx="{emu(w)}" cy="{emu(h)}"/>
        </a:xfrm>
        <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
        <a:noFill/>
        <a:ln><a:noFill/></a:ln>
      </p:spPr>
      <p:txBody>
        <a:bodyPr wrap="square" anchor="t"/>
        <a:lstStyle/>
        {''.join(paragraphs)}
      </p:txBody>
    </p:sp>
    """


def rect(
    shape_id: int,
    x: float,
    y: float,
    w: float,
    h: float,
    fill: str,
    alpha: int = 100000,
    line: str | None = None,
    radius: str = "roundRect",
) -> str:
    line_xml = (
        f'<a:ln w="12700"><a:solidFill><a:srgbClr val="{line}"/></a:solidFill></a:ln>'
        if line
        else "<a:ln><a:noFill/></a:ln>"
    )
    alpha_xml = f'<a:alpha val="{alpha}"/>' if alpha < 100000 else ""
    return f"""
    <p:sp>
      <p:nvSpPr>
        <p:cNvPr id="{shape_id}" name="Shape {shape_id}"/>
        <p:cNvSpPr/>
        <p:nvPr/>
      </p:nvSpPr>
      <p:spPr>
        <a:xfrm>
          <a:off x="{emu(x)}" y="{emu(y)}"/>
          <a:ext cx="{emu(w)}" cy="{emu(h)}"/>
        </a:xfrm>
        <a:prstGeom prst="{radius}"><a:avLst/></a:prstGeom>
        <a:solidFill><a:srgbClr val="{fill}">{alpha_xml}</a:srgbClr></a:solidFill>
        {line_xml}
      </p:spPr>
    </p:sp>
    """


def bullets(items: list[str]) -> str:
    return "\n".join(f"• {item}" for item in items)


slides = [
    {
        "title": "Тэмцээний нэгдсэн платформ",
        "subtitle": "Flutter + Firebase дээр суурилсан тэмцээн зохион байгуулах, оролцох, баг удирдах, bracket/result tracking систем",
        "points": ["Mobile/Web responsive UI", "Organizer / Participant / Admin role", "Team invite + bracket + match result workflow"],
    },
    {
        "title": "Асуудал ба хэрэгцээ",
        "subtitle": "Тэмцээн зохион байгуулах явц олон сувагт тарамдаж, бүртгэл, баг, үр дүн, мэдэгдэл нэг дор харагддаггүй.",
        "points": [
            "Оролцогч бүртгэлийн төлөв, баг, дараагийн тоглолтоо нэг газраас харах хэрэгтэй.",
            "Зохион байгуулагч bracket дээр баг оноох, match result оруулах хэрэгтэй.",
            "Бүртгэлгүй хэрэглэгчийг email invite-аар системд татах шаардлагатай.",
            "Admin талд тэмцээн, organizer эрх, хэрэглэгчийн хяналт хэрэгтэй.",
        ],
    },
    {
        "title": "Системийн зорилго",
        "subtitle": "Тэмцээний lifecycle-ийг эхнээс нь дуустал нэг platform дээр удирдах.",
        "points": [
            "Тэмцээн үүсгэх, зураг/poster upload хийх, admin approval авах.",
            "Хувийн болон багийн тэмцээнд бүртгүүлэх.",
            "Баг үүсгэх, гишүүн урих, invite accept/reject хийх.",
            "Bracket дээр баг оноох, winner/loser/score/status хадгалах.",
            "Profile дээр active/archive тэмцээн, match history автоматаар харах.",
        ],
    },
    {
        "title": "Хэрэглэгчийн role",
        "subtitle": "Role тус бүр өөр workflow-той.",
        "points": [
            "Participant: тэмцээн хайх, бүртгүүлэх, team invite авах, profile progress харах.",
            "Organizer: тэмцээн үүсгэх/edit хийх, баг болон bracket/result удирдах.",
            "Admin: тэмцээн approve/reject, organizer хүсэлт шийдэх, user management хийх.",
            "Team Leader: баг үүсгэх, email invite илгээх, гишүүн хасах.",
        ],
    },
    {
        "title": "Гол боломжууд",
        "subtitle": "Одоогийн project-д хэрэгжсэн үндсэн feature-үүд.",
        "points": [
            "Firebase Auth: email/password болон Google sign-in.",
            "Competition CRUD: title, category, date, location, rules, prizes, image/poster.",
            "Team management: багийн мэдээлэл, invite list, member remove.",
            "Invite system: registered/unregistered email invite, pending/accepted/rejected/expired status.",
            "Result system: bracket match, winner advance, loser archive, notification sync.",
        ],
    },
    {
        "title": "Технологийн бүтэц",
        "subtitle": "Flutter UI + Firebase backend.",
        "points": [
            "Frontend: Flutter Material UI, responsive mobile/desktop layout.",
            "Auth: Firebase Authentication.",
            "Database: Cloud Firestore collections.",
            "Storage: Firebase Storage competition_images folder.",
            "Realtime: Firestore snapshots ашиглан profile, invite, bracket update харуулна.",
        ],
    },
    {
        "title": "Database model",
        "subtitle": "Үндсэн collection/entity relationship.",
        "points": [
            "users: user profile, role, organizer permission.",
            "competitions: тэмцээний post, зураг, poster, status, owner.",
            "teams / teamInvites / teamNotifications: баг, invite, notification flow.",
            "registeredCompetitions: user profile дээр харагдах active/archive тэмцээн.",
            "bracketMatches / matchResults: bracket slot, score, winner/loser, match history.",
            "competitionRequests / organizerRequests: admin approval workflow.",
        ],
    },
    {
        "title": "Team invite workflow",
        "subtitle": "Бүртгэлтэй болон бүртгэлгүй хэрэглэгчийг email-ээр урина.",
        "points": [
            "Leader email оруулж invite илгээнэ.",
            "Email системд бүртгэлтэй бол uid-тэй invite үүснэ.",
            "Бүртгэлгүй бол toEmail дээр Pending invite хадгалагдана.",
            "User тухайн email-ээр бүртгүүлж/login хийвэл pending invite link хийгдэнэ.",
            "Accept хийсний дараа team member болж registeredCompetitions sync хийгдэнэ.",
        ],
    },
    {
        "title": "Bracket & Match result workflow",
        "subtitle": "Organizer bracket дээр баг оноож, үр дүн хадгална.",
        "points": [
            "Add match: round/match number автоматаар үүснэ.",
            "Slot дээр дарж тухайн тэмцээнд бүртгэлтэй багуудаас сонгоно.",
            "Хоёр баг оноогдсоны дараа winner, score, status, note, match time оруулна.",
            "Winner дараагийн round slot руу автоматаар шилжинэ.",
            "Loser Eliminated/Archived болж profile-ийн archive section руу орно.",
        ],
    },
    {
        "title": "Profile tracking",
        "subtitle": "Оролцогч өөрийн тэмцээний явцыг profile дээрээс харна.",
        "points": [
            "Одоо оролцож байна: active tournament, bracket preview, next opponent.",
            "Өмнө оролцсон тэмцээнүүд: eliminated/archive result.",
            "Match history: opponent, score, win/lose, round, time.",
            "Bracket update болон result update notification хэлбэрээр очно.",
        ],
    },
    {
        "title": "UI/UX шийдэл",
        "subtitle": "Project-ийн одоогийн visual style дээр modern clean interface нэмсэн.",
        "points": [
            "Competition detail: image header, info cards, poster, action bar.",
            "Team window: member list, invite form, sent invite status.",
            "Invite screen: notification + pending invite + accept/reject action.",
            "Bracket editor: dark neon esports style, glow cards, modal sheet.",
            "Responsive layout: mobile болон desktop дээр card/grid тохируулна.",
        ],
    },
    {
        "title": "Demo flow",
        "subtitle": "Танилцуулга хийх үед дараах дарааллаар үзүүлэхэд тохиромжтой.",
        "points": [
            "1. Organizer login → тэмцээн үүсгэх, зураг/poster upload хийх.",
            "2. Admin approve → participant талд тэмцээн харагдах.",
            "3. Participant/team leader баг үүсгэх → email invite илгээх.",
            "4. Invite авсан user accept хийх → team member болох.",
            "5. Organizer bracket slot-д баг оноох → result оруулах.",
            "6. Participant profile дээр active/archive болон match history харах.",
        ],
    },
    {
        "title": "Давуу тал",
        "subtitle": "Platform-ийн үнэ цэнэ.",
        "points": [
            "Бүртгэл, баг, invite, bracket, result нэг системд нэгдсэн.",
            "Realtime update нь organizer болон participant-ийн мэдээллийг sync байлгана.",
            "Email invite нь app-д бүртгэлгүй хэрэглэгчийг onboarding хийхэд тусална.",
            "Admin approval нь нийтлэгдэх тэмцээний чанар, найдвартай байдлыг нэмнэ.",
            "Profile archive/history нь оролцогчийн спортын амжилтын бүртгэл болно.",
        ],
    },
    {
        "title": "Цаашдын хөгжүүлэлт",
        "subtitle": "Дараагийн iteration-д нэмэх боломжтой зүйлс.",
        "points": [
            "Email deep link / Firebase Dynamic Links орлуулах custom link flow.",
            "Push notification integration.",
            "Payment/fee төлөлт болон receipt.",
            "Advanced bracket types: double elimination, group stage, round robin.",
            "Organizer analytics dashboard, export PDF/Excel.",
        ],
    },
    {
        "title": "Дүгнэлт",
        "subtitle": "Энэхүү project нь тэмцээний workflow-г digital platform болгон нэгтгэсэн mobile-first шийдэл.",
        "points": [
            "Flutter ашигласнаар олон platform дээр ажиллах UI бэлэн.",
            "Firebase ашигласнаар auth, realtime database, storage хурдан хөгжүүлэгдсэн.",
            "Team invite, bracket, match result, profile tracking зэрэг core domain feature-үүдийг хамарсан.",
            "Project нь бодит тэмцээн зохион байгуулахад хэрэглэгдэхүйц MVP түвшинд хүрсэн.",
        ],
    },
]


def slide_xml(index: int, title: str, subtitle: str, points: list[str]) -> str:
    shapes = [
        rect(2, 0, 0, 13.333, 7.5, "060713", radius="rect"),
        rect(3, 0.25, 0.22, 12.83, 7.05, "101323", alpha=88000, line="19E6FF"),
        rect(4, 0.55, 0.48, 1.1, 0.08, "F5C400", radius="rect"),
        rect(5, 1.72, 0.48, 0.72, 0.08, "FF3DF2", radius="rect"),
        text_box(6, 0.55, 0.72, 11.8, 0.8, title, 3000, "FFFFFF", True, "Title"),
        text_box(7, 0.6, 1.45, 11.7, 0.75, subtitle, 1450, "B9C7D8", False, "Subtitle"),
        rect(8, 0.65, 2.35, 12.05, 4.28, "15192C", alpha=93000, line="2D3A56"),
        text_box(9, 1.0, 2.65, 11.35, 3.65, bullets(points), 1450, "F4F7FB", False, "Bullets"),
        text_box(10, 11.75, 6.83, 0.85, 0.3, f"{index:02d}", 1150, "F5C400", True, "Slide Number"),
    ]
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld {NS}>
  <p:cSld>
    <p:bg>
      <p:bgPr>
        <a:solidFill><a:srgbClr val="060713"/></a:solidFill>
        <a:effectLst/>
      </p:bgPr>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
      {''.join(shapes)}
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>
"""


def content_types(n: int) -> str:
    overrides = "\n".join(
        f'<Override PartName="/ppt/slides/slide{i}.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>'
        for i in range(1, n + 1)
    )
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  {overrides}
</Types>
"""


def root_rels() -> str:
    return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"""


def presentation_xml(n: int) -> str:
    ids = "\n".join(
        f'<p:sldId id="{255 + i}" r:id="rId{i}"/>'
        for i in range(1, n + 1)
    )
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation {NS}>
  <p:sldIdLst>{ids}</p:sldIdLst>
  <p:sldSz cx="{SLIDE_W}" cy="{SLIDE_H}" type="screen16x9"/>
  <p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>
"""


def presentation_rels(n: int) -> str:
    rels = "\n".join(
        f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide{i}.xml"/>'
        for i in range(1, n + 1)
    )
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  {rels}
</Relationships>
"""


def core_xml() -> str:
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:dcmitype="http://purl.org/dc/dcmitype/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Тэмцээний нэгдсэн платформ</dc:title>
  <dc:creator>Codex</dc:creator>
  <cp:lastModifiedBy>Codex</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">{now}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">{now}</dcterms:modified>
</cp:coreProperties>
"""


def app_xml(n: int) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
  xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Codex PPT Generator</Application>
  <PresentationFormat>On-screen Show (16:9)</PresentationFormat>
  <Slides>{n}</Slides>
  <Company>Competition Platform Project</Company>
</Properties>
"""


def write_pptx() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(OUT, "w", compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types(len(slides)))
        z.writestr("_rels/.rels", root_rels())
        z.writestr("docProps/core.xml", core_xml())
        z.writestr("docProps/app.xml", app_xml(len(slides)))
        z.writestr("ppt/presentation.xml", presentation_xml(len(slides)))
        z.writestr("ppt/_rels/presentation.xml.rels", presentation_rels(len(slides)))
        for i, slide in enumerate(slides, 1):
            z.writestr(
                f"ppt/slides/slide{i}.xml",
                slide_xml(i, slide["title"], slide["subtitle"], slide["points"]),
            )
    print(OUT.resolve())


if __name__ == "__main__":
    write_pptx()
