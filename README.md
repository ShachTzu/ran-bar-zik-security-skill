# ran-bar-zik — סקירת אבטחה לפי עשרת הדיברות

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Claude skill (Claude Code / Claude Desktop) שסוקר קוד מול **עשרת הדיברות של
רן בר-זיק** — מפתח ועיתונאי אבטחה שהמסר החוזר שלו הוא שרוב ה"פריצות" אינן קסם:

> **"כלי הפריצה הוא הדפדפן."**

כל מה שנשלח ללקוח גלוי וניתן לעריכה ב-F12. הסקילג תופס את הכשלים לפני שמישהו
עם כלי מפתחים תופס אותם קודם.

*A Claude skill that reviews code against Ran Bar-Zik's ten commandments of
secure web development. Reports are in Hebrew by default, English on request.*

---

## התקנה

```bash
git clone https://github.com/ShachTzu/ran-bar-zik-security-skill.git
cp -r ran-bar-zik-security-skill/skills/ran-bar-zik ~/.claude/skills/
```

לפרויקט בודד: `cp -r skills/ran-bar-zik .claude/skills/`

## שימוש

```
/ran-bar-zik                  # סקירה של השינויים הנוכחיים (ברירת מחדל)
/ran-bar-zik src/api          # סקירה של נתיב
/ran-bar-zik pr 42            # סקירה של PR
/ran-bar-zik fix              # סקירה ואז תיקון הממצאים הקריטיים
/ran-bar-zik xss              # סקירה ממוקדת בדיבר אחד (xss/idor/secrets/deps/privacy/llm)
/ran-bar-zik harden           # מה חסר: CSP, HSTS, cookie flags, rate-limit, CI scans
/ran-bar-zik explain 4        # מצב לימוד — הסבר דיבר בודד
/ran-bar-zik checklist        # צ'ק-ליסט markdown ל-PR
/ran-bar-zik community        # דגשים לאפליקציית קהילה עם UGC + CSV
```

בלי ארגומנטים הסקילג בוחר יעד בעצמו: שינויים לא-מקומיטים ← דיף הענף מול `main`
← הקבצים הרגישים בפרויקט. הוא לא ישאל "מה לסקור?" לפני שניסה לגלות בעצמו.

## עשרת הדיברות

| # | הדיבר | תופס |
|---|---|---|
| 1 | לא תבטח בצד הלקוח | החלטות אבטחה ב-JS, שדות נסתרים, `if (isAdmin)` בלקוח |
| 2 | כל קלט הוא עוין | SQL/NoSQL injection, path traversal, open redirect, CSV |
| 3 | סנן פלט לפי הקשר | XSS: `innerHTML`, `dangerouslySetInnerHTML`, `javascript:` |
| 4 | בדוק הרשאה לכל אובייקט | IDOR — `GET /doc/:id` בלי בדיקת בעלות |
| 5 | סודות לא בצד לקוח | מפתחות ב-bundle, `.env` ב-git, `NEXT_PUBLIC_*_SECRET` |
| 6 | "לא פרצו לך — דלף לך" | `res.json(user)`, `SELECT *`, exports ללא הגבלה |
| 7 | הצפן הכל | md5/sha1 לסיסמאות, cookies בלי flags, `alg:none` |
| 8 | שרשרת האספקה | אין lockfile, CDN בלי SRI, תלויות פרוצות |
| 9 | הגן על ה-LLM שלך | prompt injection, פלט מודל ל-`innerHTML`/`exec` |
| 10 | פרטיות ואחריות | stack traces ללקוח, PII בלוגים, אין rate-limit |

## איך זה עובד

1. `scripts/scan.sh` סורק דגלים אדומים (10 קטגוריות, ripgrep עם fallback ל-grep).
   הפלט הוא **לידים, לא ממצאים**.
2. הסוכן קורא כל ליד בהקשר — `innerHTML` על קבוע הוא לא ממצא.
3. כל ממצא מקבל `קובץ:שורה`, **תרחיש ניצול קונקרטי**, ותיקון כדיף. אין תרחיש
   ניצול = אין ממצא.
4. פסק דין: עובר / עובר עם הסתייגויות / נכשל.

```bash
skills/ran-bar-zik/scripts/test_scan.sh
# PASS [grep]: 12/12 sections detected, clean file silent
# PASS [rg]:   12/12 sections detected, clean file silent
```

הבדיקה רצה **תחת שני המנועים**. זו לא קפדנות מיותרת: `rg` (Rust regex) ו-`grep -E`
(POSIX ERE) מקבלים דיאלקטים שונים, ובגרסה מוקדמת ביטוי אחד נדחה על-ידי `rg` בלבד —
`2>/dev/null` בלע את השגיאה והקטגוריה כולה נראתה "נקייה". היום ביטוי שנדחה מודפס
בקול (`PATTERN FAILED`) והסקריפט יוצא עם 2.

## מבנה

```
skills/ran-bar-zik/
├── SKILL.md                      # הפעולה הראשית, תת-פקודות, פורמט הדוח
├── references/
│   ├── commandments.md           # פירוט מלא + דוגמאות רע→טוב לכל דיבר
│   ├── harden.md                 # CSP, headers, cookies, rate-limit, CI
│   └── community-app.md          # דגשים לאפליקציית קהילה עם UGC ו-CSV
└── scripts/
    ├── scan.sh                   # סורק דגלים אדומים
    └── test_scan.sh              # בדיקה עצמית
```

## מגבלות

`scan.sh` הוא grep, לא AST — הוא מפספס קוד מעורפל וזרימות בין-קבציות. לכן שלב
הקריאה בהקשר הוא חובה ולא קישוט. הסקירה **אינה תחליף לבדיקת חדירה (pentest)**
או לביקורת אבטחה מלאה.

## על מה זה מבוסס

### מי זה רן בר-זיק

רן בר-זיק הוא מפתח ווב ותיק, ארכיטקט תוכנה בכיר ב-CyberArk, ועיתונאי טכנולוגיה
ב"דה מרקר" (קבוצת הארץ), ומרצה במכללת אונו.[^about][^wiki] מ-2008 הוא מפעיל את
הבלוג "אינטרנט ישראל" — בלוג תכנות בעברית שמתעדכן שבועית[^about] — וכתב סדרת
ספרי לימוד תכנות בעברית.[^books] הוא ידוע בעיקר כ-white-hat שחושף פרצות אבטחה
ודליפות מידע בגופים ישראליים.[^wiki]

### הבהרה: זו אינה רשימה רשמית

**בר-זיק לא פרסם מסמך בשם "עשרת הדיברות".** חיפוש במקורות שלו לא מצא רשימה כזו.
המספר עשר והניסוח כאן הם **סינתזה שלנו** של המסרים החוזרים בכתיבה ובחשיפות שלו,
ארוזים כצ'ק-ליסט שסוכן יכול לסקור לפיו. הפרויקט אינו מסונף אליו, לא נבדק על ידו,
ולא מייצג אותו. טעות בניסוח היא שלנו, לא שלו.

### מה נגזר ישירות מעבודתו

| מקור | הדיבר שנגזר ממנו |
|---|---|
| חשיפת אפליקציית **אלקטור** (2020): מאגר הבוחרים של הליכוד עם פרטי **6,453,254** ישראלים, שהיה נגיש דרך הדפדפן בלבד[^wiki][^elector] | **דיבר 1** — "כלי הפריצה הוא הדפדפן" |
| **"לא פרצו לנו, רק דלף לנו — לקחים טכניים מפרשת אלקטור"**[^elector] | **דיבר 6** — הסלוגן, והתובנה שהיעדר עקבות תוקף אינו הוכחה שלא דלף מידע |
| סדרת "קפטן אינטרנט" ב"דה מרקר": מערכת של **עיריית בית שמש** שחשפה אחוזי נכות ומידע על מחלות נפש של תושבים (2025)[^bs]; **400+ אלף מסמכים** עם מידע רפואי מאתר למכירת קנאביס (2024)[^cannabis] | **דיברות 6 ו-10** — מזעור חשיפה ו-PII ישראלי. אותה תבנית חוזרת: מידע רגיש נגיש לכל מי שיש לו דפדפן, בלי שאיש "פרץ" |

מכאן גם הכלל בסקילג **"מהירות לא קונה אבטחה"**: אופטימיזציה שמעבירה נתונים או
החלטות הרשאה לצד הלקוח היא רגרסיה, לא שיפור.

### מה נגזר מתקנים חיצוניים

כדי שהצ'ק-ליסט לא יהיה דעה בלבד, שאר הדיברות ממפים לתקנים מקובלים:

| דיבר | תקן |
|---|---|
| 4 | OWASP A01:2021 — Broken Access Control[^owasp-a01] |
| 2, 3 | OWASP A03:2021 — Injection (כולל XSS)[^owasp] |
| 7 | OWASP A02:2021 — Cryptographic Failures · A05 — Security Misconfiguration[^owasp] |
| 8 | OWASP A06:2021 — Vulnerable and Outdated Components[^owasp] |
| 10 | OWASP A09:2021 — Security Logging and Monitoring Failures[^owasp] |
| 9 | OWASP Top 10 for LLM Applications — LLM01 Prompt Injection · LLM05 Improper Output Handling[^owasp-llm] |
| 10 | תקנות הגנת הפרטיות (אבטחת מידע), התשע"ז-2017[^privacy] — חובות בקרת גישה, הרשאות, תיעוד ודיווח על אירועי אבטחה |

## מקורות

[^about]: [אודות רן בר-זיק ואינטרנט ישראל](https://internet-israel.com/about/), internet-israel.com.
[^wiki]: [רן בר-זיק](https://he.wikipedia.org/wiki/%D7%A8%D7%9F_%D7%91%D7%A8-%D7%96%D7%99%D7%A7), ויקיפדיה העברית.
[^books]: [ספרי פיתוח בעברית](https://hebdevbook.com/), hebdevbook.com.
[^elector]: רן בר-זיק, [לא פרצו לנו, רק דלף לנו — לקחים טכניים מפרשת אלקטור](https://internet-israel.com/פיתוח-אינטרנט/בניית-אתרי-אינטרנט-למפתחים/לא-פרצו-לנו-רק-דלף-לנו-לקחים-טכניים-מפר/), אינטרנט ישראל.
[^bs]: רן בר-זיק, [אחוזי נכות ומחלות נפש: מערכת של עיריית בית שמש חשפה מידע רגיש על תושבים](https://www.themarker.com/captain-internet/2025-08-25/ty-article/.premium/00000198-e064-d9a7-add9-e2e51a110000), קפטן אינטרנט, TheMarker, 25.8.2025 (תוכן בתשלום).
[^cannabis]: רן בר-זיק, [יותר מ-400 אלף מסמכים: פרטים אישיים ומידע רפואי רגיש דלפו מאתר לממכר קנאביס](https://www.themarker.com/captain-internet/2024-09-15/ty-article/.premium/00000191-e15d-d084-a5db-eb5f16230000), קפטן אינטרנט, TheMarker, 15.9.2024 (תוכן בתשלום).
[^owasp]: [OWASP Top 10:2021](https://owasp.org/Top10/2021/), OWASP Foundation.
[^owasp-a01]: [A01:2021 — Broken Access Control](https://owasp.org/Top10/2021/A01_2021-Broken_Access_Control/), OWASP Top 10:2021.
[^owasp-llm]: [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/), OWASP Gen AI Security Project.
[^privacy]: [תקנות הגנת הפרטיות (אבטחת מידע), התשע"ז-2017](https://www.nevo.co.il/law_html/law00/144811.htm), נבו. ראו גם [דף התקנות](https://www.gov.il/he/pages/data_security_regulation) באתר הרשות להגנת הפרטיות.

כל הקישורים נבדקו ב-21.7.2026.

## רישיון

MIT — ראה [LICENSE](LICENSE). הסקילג הוא יישום עצמאי ואינו מסונף לרן בר-זיק.
