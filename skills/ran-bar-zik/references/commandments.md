# עשרת הדיברות — פירוט מלא, סימני אזהרה ודוגמאות

לכל דיבר: מה בודקים, דגלים אדומים לחיפוש בקוד, ודוגמת "רע → טוב". השתמש בזה כדי
לתת ציון מדויק ולנסח תיקון קונקרטי.

---

## 1. לא תבטח בצד הלקוח — "כלי הפריצה הוא הדפדפן"

**העיקרון:** כל דבר שמגיע ללקוח נמצא בשליטת המשתמש. F12 + כלי מפתחים = כלי הפריצה.
ולידציה, מחירים, הרשאות, כמויות, `disabled`/`hidden` — כולם ניתנים לעריכה בדפדפן.

**דגלים אדומים:**
- החלטת אבטחה/עסק שמסתמכת רק על בדיקה ב-JavaScript של הלקוח.
- שדות `type="hidden"`, `disabled`, או ערכים שמגיעים מהלקוח ומשמשים לחישוב מחיר,
  role, בעלות, או הרשאה בלי בדיקה חוזרת בשרת.
- הסתרת כפתור/אלמנט (`display:none`) כ"הרשאה".
- `if (user.isAdmin)` שמוכרע בקוד לקוח בלבד.

**רע:**
```js
// הלקוח שולח את המחיר ואת ה-role
fetch('/api/order', { body: JSON.stringify({ price: cartPrice, role: 'admin' }) })
```
**טוב:** השרת מחשב מחיר מהמוצרים לפי ה-DB, וה-role נלקח מה-session/טוקן המאומת —
לעולם לא מגוף הבקשה.

---

## 2. כל קלט הוא עוין עד שהוכח אחרת

**העיקרון:** ולד ונקה **בשרת** כל קלט — body, query, params, headers, cookies,
שמות קבצים, תאי CSV, webhooks. allow-list (מה מותר) עדיף על deny-list (מה אסור).

**דגלים אדומים:**
- שימוש ישיר בפרמטר מהבקשה בתוך שאילתה, נתיב קובץ, פקודת shell, או redirect.
- אין schema validation (Zod/Joi/כד') על גבול הכניסה.
- קונקטנציה של קלט לשאילתת SQL/NoSQL (SQL/NoSQL injection).
- `res.redirect(req.query.next)` (open redirect); `require`/`fs` על נתיב מהמשתמש (path traversal).

**רע:**
```js
db.query(`SELECT * FROM users WHERE email='${req.body.email}'`)
```
**טוב:** שאילתות פרמטריות/prepared statements + ולידציית schema לפני העיבוד.

---

## 3. סנן פלט לפי הקשר — הגנת XSS

**העיקרון:** XSS נמנע ב**קידוד הפלט לפי ההקשר** (HTML / attribute / JS / URL), לא
בסינון הקלט. הישען על escaping אוטומטי של הפריימוורק, על **Trusted Types** ועל
**CSP**. כפי שבר-זיק מדגיש: **WAF וסינון blacklist לא יעזרו** — קל לעקוף אותם.

**דגלים אדומים:**
- `innerHTML`, `outerHTML`, `document.write`, `dangerouslySetInnerHTML`,
  `v-html`, `insertAdjacentHTML` עם תוכן מהמשתמש.
- בניית HTML במחרוזות במקום textContent/עצי DOM.
- ניקוי "ידני" עם regex/replace כתחליף לספרייה (DOMPurify) או לקידוד.
- אין CSP; אין `nonce`/Trusted Types.

**רע:**
```js
el.innerHTML = "שלום " + userName;
```
**טוב:** `el.textContent = "שלום " + userName;` — ואם *חייבים* HTML, לעבור דרך
DOMPurify + CSP + Trusted Types.

---

## 4. בדוק הרשאה לכל אובייקט — IDOR

**העיקרון:** IDOR = גישה לאובייקט של מישהו אחר ע"י שינוי מזהה. לעולם אל תסמוך על
מזהה "עמום" או רץ. בכל בקשה בדוק בשרת ש**המשתמש המחובר בעל הרשאה לאובייקט הזה**.

**דגלים אדומים:**
- `GET /api/users/:id` / `/orders/:id` שמחזיר לפי ה-id בלבד, בלי לבדוק בעלות.
- הנחה ש"אף אחד לא ינחש UUID".
- בדיקת הרשאה ברמת ה-route בלבד ("מחובר?") ולא ברמת האובייקט ("שלך?").
- מזהים רצים חשופים בכתובות/תגובות.

**רע:**
```js
app.get('/api/doc/:id', (req,res) => res.json(db.getDoc(req.params.id)))
```
**טוב:** `db.getDoc({ id: req.params.id, ownerId: req.user.id })` — או בדיקת
`doc.ownerId === req.user.id` לפני ההחזרה, אחרת 403/404.

---

## 5. סודות לא נמצאים בקוד צד לקוח

**העיקרון:** אין מפתחות API, טוקנים, סיסמאות, connection strings ב-frontend או
ב-repo. סודות ב-env / secret manager. סוד שדלף — **מחליפים אותו**, לא מסתירים.

**דגלים אדומים:**
- מפתח/טוקן קשיח בקוד JS/צד לקוח, ב-bundle, או ב-`NEXT_PUBLIC_`/`VITE_` שאמור להיות סודי.
- `.env`, מפתחות `.pem`, קובצי credentials שנכנסו ל-git.
- טוקן "פרטי" שנשלח ללקוח כי "הוא בכל מקרה מוצפן".
- Basic-auth/סיסמה בתוך URL.

**רע:** `const stripeSecret = "sk_live_...."` בקוד לקוח.
**טוב:** הקריאה הרגישה עוברת בשרת; ללקוח מגיע רק מפתח פומבי מיועד-לקוח (אם בכלל).

---

## 6. "לא פרצו לך — דלף לך" — מזעור חשיפת מידע

**העיקרון:** רוב ה"פריצות" הן מידע שנחשף לכל מי שיש לו דפדפן. אל תחזיר מה-API יותר
ממה שנחוץ למסך. בדוק בטאב הרשת מה ה-endpoint *באמת* מחזיר.

**דגלים אדומים:**
- `res.json(user)` שמחזיר את כל הרשומה (hash סיסמה, טלפון, ת"ז, שדות פנימיים).
- `SELECT *` שנשלח כמו-שהוא ללקוח.
- endpoints "פנימיים"/דיבוג פתוחים בפרודקשן; רשימות/exports ללא הגבלה (מדביקים כל המשתמשים).
- מטא-דאטה עודף בתגובות שגיאה.

**רע:** `res.json(await db.users.find())` (הכל, לכולם).
**טוב:** DTO/projection מפורש — רק השדות שהמסך צריך, ורק לרשומות שמותר למשתמש לראות.

---

## 7. הצפן הכל — בתנועה ובמנוחה

**העיקרון:** HTTPS + HSTS בכל מקום. סיסמאות ב-hash איטי ומלוח (bcrypt/argon2/scrypt),
לא MD5/SHA1 ולא plaintext. הצפן מידע רגיש ב-DB. לסודות ארוכי-טווח — לחשוב על עמידות
פוסט-קוונטית.

**דגלים אדומים:**
- `http://` בקוד/קונפיג, cookies בלי `Secure`/`HttpOnly`/`SameSite`.
- אחסון סיסמה בטקסט גלוי או ב-hash מהיר (md5/sha1/sha256 ללא salt).
- קריפטו "ביתי" במקום ספרייה סטנדרטית; JWT עם `alg:none` או סוד חלש.
- מידע רגיש (ת"ז, בריאות, מיקום) לא מוצפן ב-rest.

**רע:** `user.password = md5(pw)`.
**טוב:** `await bcrypt.hash(pw, 12)` + אחסון מוצפן למידע רגיש + cookies מאובטחות.

---

## 8. שרשרת האספקה היא שטח תקיפה

**העיקרון:** התלויות שלך — במיוחד ספריות צד-לקוח — הן חלק ממשטח התקיפה. בדוק אותן,
נעל גרסאות, ואמת סקריפטים חיצוניים.

**דגלים אדומים:**
- אין lockfile; גרסאות `^`/`latest` פרוצות.
- `<script src="https://cdn...">` בלי `integrity` (SRI).
- ספריות נטושות/חולשות ידועות; העתקה של קוד לא מאומת מ-npm/גיטהאב.
- הרבה JS צד-שלישי (טאגים שיווקיים) עם גישה מלאה ל-DOM.

**רע:** משיכת ספרייה מ-CDN חיצוני בלי SRI ובלי pin.
**טוב:** גרסאות נעולות, `npm audit`/סורק תלויות ב-CI, SRI לכל סקריפט חיצוני, מזעור צד-שלישי.

---

## 9. הגן על ה-LLM / הסוכן שלך

**העיקרון:** אם יש LLM/סוכן במערכת — הפלט שלו הוא קלט לא-אמין. הגן מפני prompt
injection, שים safeguards על קלט ופלט, ואל תיתן לסוכן הרשאות בלי גבולות.

**דגלים אדומים:**
- הזרקת פלט מודל ישירות ל-HTML/DB/shell/eval בלי סינון.
- prompt שמערבב הוראות מערכת עם תוכן משתמש בלי הפרדה.
- סוכן עם גישה לכלים רגישים (מחיקה, תשלום, קריאת קבצים) בלי אישור/גבולות.
- אמון בפלט מודל להחלטות הרשאה.

**רע:** `db.exec(llmOutput)` / `el.innerHTML = llmAnswer`.
**טוב:** ולידציית פלט מול schema, escaping כמו לכל קלט משתמש, הרשאות מינימום לכלים,
ו-human-in-the-loop לפעולות רגישות.

---

## 10. פרטיות, שקיפות ואחריות

**העיקרון:** מזער מידע אישי, עמוד בתקנות הגנת הפרטיות, אל תדליף פרטים בשגיאות ובלוגים,
ותכנן דיווח אחראי. תמיד בהנחה שמישהו יבדוק אותך — אז תעדיף שקיפות.

**דגלים אדומים:**
- איסוף/שמירת מידע אישי מעבר לנחוץ; שמירה ללא תוקף/מחיקה.
- stack trace / פרטי DB בשגיאות שמגיעות למשתמש.
- לוגים שמכילים סיסמאות, טוקנים, ת"ז, מיקום.
- אין rate-limiting/הגנה על טפסים; אין מדיניות מחיקה/הסכמה.

**רע:** `catch(e){ res.status(500).send(e.stack) }`, לוג של `req.body` עם סיסמה.
**טוב:** שגיאה גנרית ללקוח + לוג פנימי מנוקה מסודות, מזעור נתונים, tokenization/הסתרה
של PII בלוגים, ומדיניות שמירה/מחיקה ברורה.

---

## מקורות לכל דיבר

לשימוש כשצריך לגבות ממצא בהפניה חיצונית בדוח. הפירוט המלא על מקור הדיברות —
כולל ההבהרה שבר-זיק לא פרסם רשימה כזו — נמצא ב-README של הפרויקט.

| דיבר | מקור |
|---|---|
| 1 | פרשת אלקטור (2020): מאגר בוחרים עם 6,453,254 ישראלים, נגיש דרך דפדפן בלבד — [ויקיפדיה](https://he.wikipedia.org/wiki/%D7%A8%D7%9F_%D7%91%D7%A8-%D7%96%D7%99%D7%A7) |
| 2 | [OWASP A03:2021 — Injection](https://owasp.org/Top10/2021/A03_2021-Injection/) |
| 3 | [OWASP A03:2021 — Injection](https://owasp.org/Top10/2021/A03_2021-Injection/) · [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html) |
| 4 | [OWASP A01:2021 — Broken Access Control](https://owasp.org/Top10/2021/A01_2021-Broken_Access_Control/) |
| 5 | [OWASP A05:2021 — Security Misconfiguration](https://owasp.org/Top10/2021/A05_2021-Security_Misconfiguration/) · [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) |
| 6 | רן בר-זיק, [לא פרצו לנו, רק דלף לנו](https://internet-israel.com/פיתוח-אינטרנט/בניית-אתרי-אינטרנט-למפתחים/לא-פרצו-לנו-רק-דלף-לנו-לקחים-טכניים-מפר/) · [OWASP A01:2021](https://owasp.org/Top10/2021/A01_2021-Broken_Access_Control/) (CWE-200) |
| 7 | [OWASP A02:2021 — Cryptographic Failures](https://owasp.org/Top10/2021/A02_2021-Cryptographic_Failures/) · [Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html) |
| 8 | [OWASP A06:2021 — Vulnerable and Outdated Components](https://owasp.org/Top10/2021/A06_2021-Vulnerable_and_Outdated_Components/) |
| 9 | [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) — LLM01 Prompt Injection, LLM05 Improper Output Handling |
| 10 | [OWASP A09:2021 — Security Logging and Monitoring Failures](https://owasp.org/Top10/2021/A09_2021-Security_Logging_and_Monitoring_Failures/) · [תקנות הגנת הפרטיות (אבטחת מידע), התשע"ז-2017](https://www.nevo.co.il/law_html/law00/144811.htm) |
